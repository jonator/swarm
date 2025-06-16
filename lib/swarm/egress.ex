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

  def reply(
        %{"linear_issue_id" => _, "linear_app_user_id" => _, "linear_comment_id" => _} =
          external_ids,
        message
      ) do
    LinearDispatch.reply(external_ids, message)
  end

  def reply(%Event{source: other_source}, _message) do
    {:error, "Egress.reply/1 received non-Linear event: #{other_source}"}
  end
end
