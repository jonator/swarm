defmodule Swarm.Agents.Message do
  @moduledoc """
  Schema for agent messages that represent communication during agent execution.

  Messages follow the LangChain message format with types for system, user, assistant, and tool messages.
  Each message belongs to an agent and contains content and metadata for conversation tracking.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Swarm.Agents.Agent

  schema "agent_messages" do
    # See: https://hexdocs.pm/langchain/LangChain.Message.html
    field :type, Ecto.Enum, values: [:system, :user, :assistant, :tool]
    field :content, :string
    belongs_to :agent, Agent

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :type, :metadata])
    |> validate_required([:content, :type])
  end
end
