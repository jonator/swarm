defmodule Swarm.Workers do
  @moduledoc """
  Worker spawning and orchestration for coding agents.

  This module handles the initial processing of events and determines whether
  to spawn a researcher agent (for insufficient context) or a coder agent
  (for sufficient context to implement directly).
  """

  require Logger
  alias Swarm.Ingress.Event
  alias Swarm.Egress
  alias Swarm.Agents
  alias Swarm.Agents.Agent

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

    with {:ok, agent_type} <- determine_agent_type(agent_attrs),
         {:ok, %{agent: agent, action: action}} <-
           create_or_update_agent(agent_attrs, agent_type, event) do
      case action do
        :created ->
          with {:ok, msg} <- Egress.acknowledge(event),
               {:ok, job} <- schedule_agent_worker(agent) do
            Logger.info("Successfully spawned #{agent_type} agent #{agent.id}")
            {:ok, agent, job, msg}
          else
            {:error, reason} = error ->
              Logger.error("Failed to acknowledge event or schedule agent: #{reason}")
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

  @doc """
  Determines whether the context has enough information for direct implementation
  or requires research first.
  """
  def determine_agent_type(agent_attrs) do
    context = Map.get(agent_attrs, :context, "")

    # Check if context has sufficient detail for implementation
    has_enough_context = analyze_context_sufficiency(context)

    agent_type = if has_enough_context, do: :coder, else: :researcher

    Logger.debug("Determined agent type: #{agent_type} based on context analysis")
    {:ok, agent_type}
  end

  def analyze_context_sufficiency(context) when is_binary(context) do
    context_length = String.length(context)

    # Basic heuristics for context sufficiency
    has_technical_details =
      String.contains?(context, ["code", "function", "file", "implementation", "bug", "error"])

    has_clear_requirements =
      String.contains?(context, ["should", "need", "implement", "fix", "add", "remove", "update"])

    has_sufficient_length = context_length > 100

    has_specific_mentions =
      String.contains?(context, ["README", "documentation", "API", "database", "config"])

    # Context is sufficient if it has technical details, clear requirements,
    # sufficient length, and specific mentions
    has_technical_details && has_clear_requirements && has_sufficient_length &&
      has_specific_mentions
  end

  def analyze_context_sufficiency(_), do: false

  defp create_or_update_agent(agent_attrs, agent_type, event) do
    # Check for existing pending agent with overlapping agent_attrs
    case Agents.find_pending_agent_with_any_ids(agent_attrs) do
      nil ->
        # Create new agent
        with {:ok, agent} <- create_new_agent(agent_attrs, agent_type, event) do
          {:ok, %{agent: agent, action: :created}}
        end

      existing_agent ->
        # Update existing agent with new data
        Logger.info("Found existing pending agent #{existing_agent.id}, updating data")

        case update_existing_agent(existing_agent, agent_attrs, agent_type) do
          {:ok, agent} -> {:ok, %{agent: agent, action: :updated}}
          error -> error
        end
    end
  end

  defp create_new_agent(agent_attrs, agent_type, event) do
    # Use external_ids from agent_attrs, or fall back to event external_ids
    external_ids = Map.get(agent_attrs, :external_ids, event.external_ids || %{})

    agent_params = %{
      name: generate_agent_name(agent_type, agent_attrs),
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

  defp update_existing_agent(agent, agent_attrs, agent_type) do
    # Use external_ids from agent_attrs, merge with existing agent external_ids
    new_external_ids = Map.get(agent_attrs, :external_ids, %{})
    merged_external_ids = Map.merge(agent.external_ids || %{}, new_external_ids)

    update_params = %{
      context: Map.get(agent_attrs, :context, agent.context),
      type: agent_type,
      external_ids: merged_external_ids,
      # Keep the agent as pending, don't change status
      status: :pending
    }

    Agents.update_agent(agent, update_params)
  end

  def generate_agent_name(agent_type, agent_attrs) do
    # Get external IDs from external_ids map
    external_ids = Map.get(agent_attrs, :external_ids, %{})
    linear_id = external_ids["linear_issue_id"]
    github_id = external_ids["github_issue_id"]

    case {agent_type, linear_id, github_id} do
      {:researcher, linear_id, _} when not is_nil(linear_id) ->
        "Research Agent - Linear Issue #{String.slice(linear_id, 0, 8)}"

      {:coder, linear_id, _} when not is_nil(linear_id) ->
        "Coding Agent - Linear Issue #{String.slice(linear_id, 0, 8)}"

      {:researcher, _, github_id} when not is_nil(github_id) ->
        "Research Agent - GitHub Issue #{github_id}"

      {:coder, _, github_id} when not is_nil(github_id) ->
        "Coding Agent - GitHub Issue #{github_id}"

      {:researcher, _, _} ->
        "Research Agent - #{DateTime.utc_now() |> DateTime.to_unix()}"

      {:coder, _, _} ->
        "Coding Agent - #{DateTime.utc_now() |> DateTime.to_unix()}"
    end
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
