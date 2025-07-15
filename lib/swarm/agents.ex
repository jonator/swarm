defmodule Swarm.Agents do
  @moduledoc """
  The Agents context.
  """

  import Ecto.Query, warn: false
  alias Swarm.Repo

  alias Swarm.Agents.Agent
  alias Swarm.Accounts.User
  alias Swarm.Agents.Message
  alias Swarm.Ingress.Event

  # Existing code remains the same...

  @doc """
  Handles agent logic for a new event, ensuring one agent per issue.

  Returns the appropriate agent to use or creates a new one.
  """
  def handle_agent_for_event(%Event{} = event) do
    # First, try to find an existing pending or running agent
    existing_agent = find_pending_agent_with_any_ids(event.external_ids)

    case existing_agent do
      # If an agent is pending, update it directly
      %Agent{status: :pending} = agent ->
        {:pending, agent}

      # If an agent is working, prepare to send a message
      %Agent{status: :running} = agent ->
        {:working, agent}

      # If an agent is failed or completed, spawn a new worker
      %Agent{status: :failed} = agent ->
        {:spawn_new, agent}

      %Agent{status: :completed} = agent ->
        {:spawn_new, agent}

      # No existing agent found, create a new one
      nil ->
        case create_agent(%{
               external_ids: event.external_ids,
               repository_id: event.repository_external_id,
               status: :pending
             }) do
          {:ok, new_agent} -> {:new, new_agent}
          {:error, _changeset} -> {:error, nil}
        end
    end
  end

  @doc """
  Sends a message to an existing agent or creates a new message.
  """
  def send_message_to_agent(%Agent{} = agent, message_content) do
    case create_message(agent.id, %{
           content: message_content,
           type: :user
         }) do
      {:ok, message} -> {:ok, message}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # Rest of the existing code remains the same...
end
