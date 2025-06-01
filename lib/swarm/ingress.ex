defmodule Swarm.Ingress do
  @moduledoc """
  Main entry point for all external events into the Swarm system.

  This module routes events from various sources (GitHub, Linear, Slack, Manual)
  to their appropriate handlers and coordinates the agent spawning process.
  """

  alias Swarm.Ingress.Event
  alias Swarm.Ingress.GitHubHandler
  alias Swarm.Ingress.LinearHandler
  alias Swarm.Ingress.SlackHandler
  alias Swarm.Ingress.ManualHandler

  @doc """
  Main entry point for processing events from any source.

  ## Parameters
    - event_data: Raw event data from webhook or manual trigger
    - source: Event source (:github, :linear, :slack, :manual)
    - opts: Additional options like user context

  ## Returns
    - `{:ok, agent}` - Successfully created and queued agent
    - `{:ok, :ignored}` - Event was valid but ignored (e.g., not relevant)
    - `{:error, reason}` - Event processing failed
  """
  def process_event(event_data, source, opts \\ []) do
    with {:ok, event} <- Event.new(event_data, source, opts),
         {:ok, agent_attrs} <- route_event(event) do
      {:ok, agent_attrs}
    end
  end

  # Routes an event to the appropriate handler based on its source.
  # Returns attributes used for spawning an agent.
  defp route_event(%Event{source: :github} = event) do
    GitHubHandler.handle(event)
  end

  defp route_event(%Event{source: :linear} = event) do
    LinearHandler.handle(event)
  end

  defp route_event(%Event{source: :slack} = event) do
    SlackHandler.handle(event)
  end

  defp route_event(%Event{source: :manual} = event) do
    ManualHandler.handle(event)
  end
end
