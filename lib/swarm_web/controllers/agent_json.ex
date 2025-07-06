defmodule SwarmWeb.AgentJSON do
  alias Swarm.Agents.Agent
  alias Swarm.Agents.Message

  @doc """
  Renders a list of agents.
  """
  def index(%{agents: agents}) do
    %{agents: for(agent <- agents, do: data(agent))}
  end

  def index(%{messages: messages}) do
    %{messages: for(message <- messages, do: data(message))}
  end

  @doc """
  Renders a single agent.
  """
  def show(%{agent: agent}) do
    %{agent: data(agent)}
  end

  defp data(%Agent{} = agent) do
    %{
      id: agent.id,
      name: agent.name,
      context: agent.context,
      status: agent.status,
      source: agent.source,
      type: agent.type,
      external_ids: agent.external_ids,
      started_at: agent.started_at,
      completed_at: agent.completed_at,
      oban_job_id: agent.oban_job_id,
      user_id: agent.user_id,
      repository_id: agent.repository_id,
      project_id: agent.project_id,
      created_at: agent.inserted_at,
      updated_at: agent.updated_at
    }
  end

  defp data(%Message{} = message) do
    %{
      id: message.id,
      content: message.content,
      index: message.index,
      type: message.type,
      created_at: message.inserted_at,
      updated_at: message.updated_at
    }
  end
end
