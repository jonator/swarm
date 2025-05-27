defmodule Swarm.Agents.Agent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Swarm.Accounts.User
  alias Swarm.Repositories.Repository
  alias Swarm.Projects.Project

  schema "agents" do
    field :name, :string
    field :context, :string
    field :status, Ecto.Enum, values: [:pending, :running, :completed, :failed]
    field :trigger, Ecto.Enum, values: [:frontend, :linear, :slack, :github]
    field :type, Ecto.Enum, values: [:researcher, :coder, :code_reviewer]
    field :trigger_source_id, :string
    field :github_pull_request_id, :string
    field :github_issue_id, :string
    field :linear_issue_id, :string
    field :slack_thread_id, :string
    field :started_at, :naive_datetime
    field :completed_at, :naive_datetime
    belongs_to :oban_job, Oban.Job
    belongs_to :user, User
    belongs_to :repository, Repository
    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(agent, attrs) do
    agent
    |> cast(attrs, [
      :name,
      :context,
      :status,
      :trigger,
      :type,
      :trigger_source_id,
      :github_pull_request_id,
      :github_issue_id,
      :linear_issue_id,
      :slack_thread_id,
      :started_at,
      :completed_at
    ])
    |> validate_required([
      :name,
      :context,
      :status,
      :trigger,
      :type
    ])
  end
end
