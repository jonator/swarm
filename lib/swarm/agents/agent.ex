defmodule Swarm.Agents.Agent do
  @moduledoc """
  Schema for AI coding agents that can be spawned to work on repositories.

  Agents represent autonomous AI workers that can perform different types of tasks:
  - Researcher: Analyze code and provide insights
  - Coder: Implement features and fix bugs
  - Code Reviewer: Review pull requests and provide feedback

  Agents are triggered from various sources (Linear, GitHub, Slack, manual) and work
  within the context of specific repositories and projects.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Swarm.Accounts.User
  alias Swarm.Repositories.Repository
  alias Swarm.Projects.Project
  alias Swarm.Agents.Message

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "agents" do
    field :name, :string
    field :context, :string
    field :status, Ecto.Enum, values: [:pending, :running, :completed, :failed]
    field :source, Ecto.Enum, values: [:manual, :linear, :slack, :github]
    field :type, Ecto.Enum, values: [:researcher, :coder, :code_reviewer]
    field :external_ids, :map, default: %{}
    field :started_at, :naive_datetime
    field :completed_at, :naive_datetime
    belongs_to :oban_job, Oban.Job
    belongs_to :user, User
    belongs_to :repository, Repository
    belongs_to :project, Project
    has_many :messages, Message

    timestamps()
  end

  @doc false
  def changeset(agent, attrs) do
    agent
    |> cast(attrs, [
      :name,
      :context,
      :status,
      :source,
      :type,
      :external_ids,
      :started_at,
      :completed_at,
      :user_id,
      :repository_id,
      :project_id,
      :oban_job_id
    ])
    |> validate_required([
      :name,
      :context,
      :status,
      :source,
      :type,
      :repository_id,
      :user_id
    ])
  end
end
