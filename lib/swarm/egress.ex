defmodule Swarm.Egress do
  @moduledoc """
  Egress module for sending messages or data to external systems.
  """

  alias Swarm.Ingress.Event
  alias Swarm.Egress.LinearDispatch

  @doc """
  Acknowledge a message.

  Per recommendation: https://linear.app/developers/agents#recommendations
  """
  def acknowledge(%Event{source: :linear} = event) do
    LinearDispatch.acknowledge(event)
  end

  def acknowledge(%Event{source: other_source}) do
    {:error, "Egress.acknowledge/1 received non-Linear event: #{other_source}"}
  end
end
