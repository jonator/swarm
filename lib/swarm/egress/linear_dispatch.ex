defmodule Swarm.Egress.LinearDispatch do
  @moduledoc """
  Egress module for sending messages or data to Linear.
  """

  alias Swarm.Ingress.Event
  alias Swarm.Services.Linear

  @acknowledge_emoji "eyes"

  def acknowledge(%Event{
        source: :linear,
        external_ids: %{
          linear_issue_id: _issue_id,
          linear_app_user_id: app_user_id,
          linear_comment_id: comment_id
        }
      }) do
    with {:ok, _} <- Linear.comment_reaction(app_user_id, comment_id, @acknowledge_emoji) do
      {:ok, "Acknowledged comment #{comment_id}, with emoji #{@acknowledge_emoji}"}
    end
  end

  def acknowledge(%Event{
        source: :linear,
        external_ids: %{linear_issue_id: issue_id, linear_app_user_id: app_user_id}
      }) do
    with {:ok, _} <- Linear.issue_reaction(app_user_id, issue_id, @acknowledge_emoji) do
      {:ok, "Acknowledged issue #{issue_id}, with emoji #{@acknowledge_emoji}"}
    end
  end

  def acknowledge(event) do
    {:error, "Egress.Linear.acknowledge/1 - event not supported: #{inspect(event)}"}
  end
end
