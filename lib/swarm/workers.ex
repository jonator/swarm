defmodule Swarm.Workers do
  @moduledoc """
  Worker spawning and orchestration for coding agents.

  This module handles the initial processing of events and determines whether
  to spawn a researcher agent (for insufficient context) or a coder agent
  (for sufficient context to implement directly).
  """

  require Logger
  alias Swarm.Ingress.Event
  alias Swarm.Repo
  alias Swarm.Egress
  alias Swarm.Agents
  alias Swarm.Agents.Agent
  alias Swarm.Instructor.{AgentType, AgentName}

  @agent_update_window_seconds 30

  @doc """
  Spawns an appropriate agent based on the event context and agent attributes.

  This function:
  1. Acknowledges the event
  2. Analyzes the context to determine if there's enough information for coding
  3. Creates an agent record with appropriate type (researcher or coder)
  4. Schedules the worker job 30 seconds in the future
  5. Handles duplicate pending agents by updating existing ones

  Returns {:ok, agent, job, ack_msg} on success.
  Returns {:error, reason} on failure.
  """
  def spawn(agent_attrs, %Event{} = event) do
    Logger.info("Processing agent spawn request for event type: #{event.type}")

    context = Map.get(agent_attrs, :context, "")

    # Run agent type and agent name determination concurrently
    type_task = Task.async(fn -> AgentType.determine(context) end)
    name_task = Task.async(fn -> AgentName.generate_agent_name(context) end)
    [type_result, name_result] = Task.await_many([type_task, name_task], 15_000)

    frontend_origin = Application.get_env(:swarm, :frontend_origin)

    with {:ok, %AgentType{agent_type: agent_type}} <- type_result,
         {:ok, %AgentName{agent_name: agent_name}} <- name_result,
         {:ok, %{agent: agent, action: action}} <-
           create_or_update_agent(agent_attrs, agent_type, agent_name, event) do
      repo = Repo.preload(agent, :repository).repository

      case action do
        :created ->
          with {:ok, job} <- schedule_agent_worker(agent),
               {:ok, _msg} <- Egress.acknowledge(event, agent_attrs.repository),
               {:ok, _msg} <-
                 Egress.reply(
                   event,
                   repo,
                   "On it 🤖. Follow along at #{frontend_origin}/#{repo.owner}/#{repo.name}/agents/#{agent.id}"
                 ) do
            Logger.info("Successfully spawned #{agent_type} agent #{agent.id}")
            {:ok, agent, job}
          else
            {:error, reason} = error ->
              Logger.error("Failed to schedule agent or acknowledge event: #{reason}")
              error
          end

        :updated ->
          Logger.info("Updated existing pending agent #{agent.id}")
          {:ok, :updated}
      end
    else
      {:error, reason} = error ->
        Logger.error("Failed to spawn agent: #{reason}")
        error
    end
  end

  defp create_or_update_agent(agent_attrs, agent_type, agent_name, event) do
    # Check for existing pending agent with overlapping agent_attrs
    case Agents.find_pending_agent_with_any_ids(agent_attrs) do
      nil ->
        # Create new agent
        with {:ok, agent} <- create_new_agent(agent_attrs, agent_type, agent_name, event) do
          {:ok, %{agent: agent, action: :created}}
        end

      existing_agent ->
        # Update existing agent with new data
        Logger.info("Found existing pending agent #{existing_agent.id}, updating data")

        case update_existing_agent(existing_agent, agent_attrs, agent_type, agent_name) do
          {:ok, agent} -> {:ok, %{agent: agent, action: :updated}}
          error -> error
        end
    end
  end

  defp create_new_agent(agent_attrs, agent_type, agent_name, event) do
    # Use external_ids from agent_attrs, or fall back to event external_ids
    external_ids = Map.get(agent_attrs, :external_ids, event.external_ids || %{})

    agent_params = %{
      name: agent_name,
      context: Map.get(agent_attrs, :context, ""),
      status: :pending,
      source: Map.get(agent_attrs, :source, event.source),
      type: agent_type,
      user_id: Map.get(agent_attrs, :user_id),
      repository_id: Map.get(agent_attrs, :repository, %{id: agent_attrs[:repository_id]}).id,
      external_ids: external_ids
    }

    Agents.create_agent(agent_params)
  end

  defp update_existing_agent(agent, agent_attrs, agent_type, agent_name) do
    # Use external_ids from agent_attrs, merge with existing agent external_ids
    new_external_ids = Map.get(agent_attrs, :external_ids, %{})
    merged_external_ids = Map.merge(agent.external_ids || %{}, new_external_ids)

    update_params = %{
      context: Map.get(agent_attrs, :context, agent.context),
      type: agent_type,
      name: agent_name,
      external_ids: merged_external_ids,
      # Keep the agent as pending, don't change status
      status: :pending
    }

    Agents.update_agent(agent, update_params)
  end

  defp schedule_agent_worker(%Agent{id: agent_id, type: :researcher}) do
    %{agent_id: agent_id}
    |> Swarm.Workers.Researcher.new(schedule_in: @agent_update_window_seconds)
    |> Oban.insert()
  end

  defp schedule_agent_worker(%Agent{id: agent_id, type: :coder}) do
    %{agent_id: agent_id}
    |> Swarm.Workers.Coder.new(schedule_in: @agent_update_window_seconds)
    |> Oban.insert()
  end
end
