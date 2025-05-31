defmodule Swarm.Agents.Message do
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
