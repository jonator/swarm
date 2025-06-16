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
          "linear_issue_id" => _issue_id,
          "linear_app_user_id" => app_user_id,
          "linear_comment_id" => comment_id
        }
      }) do
    with {:ok, _} <- Linear.comment_reaction(app_user_id, comment_id, @acknowledge_emoji) do
      {:ok, "Acknowledged comment #{comment_id}, with emoji #{@acknowledge_emoji}"}
    end
  end

  def acknowledge(%Event{
        source: :linear,
        external_ids: %{"linear_issue_id" => issue_id, "linear_app_user_id" => app_user_id}
      }) do
    with {:ok, _} <- Linear.issue_reaction(app_user_id, issue_id, @acknowledge_emoji) do
      {:ok, "Acknowledged issue #{issue_id}, with emoji #{@acknowledge_emoji}"}
    end
  end

  def acknowledge(event) do
    {:error, "Egress.Linear.acknowledge/1 - event not supported: #{inspect(event)}"}
  end

  @doc """
  Reply to a Linear issue event. If linear_parent_comment_id is provided, replies to that comment already on the issue.

  Note: With Linear API, the parent comment ID is always the root comment ID on the issue (vs the immediate child comment ID).
  """
  def reply(
        %{
          "linear_issue_id" => issue_id,
          "linear_app_user_id" => app_user_id,
          "linear_parent_comment_id" => parent_comment_id
        },
        message
      ) do
    with {:ok, _} <- Linear.create_comment(app_user_id, issue_id, message, parent_comment_id) do
      {:ok, "Replied to issue #{issue_id} parent comment #{parent_comment_id}"}
    end
  end

  def reply(
        %{"linear_issue_id" => issue_id, "linear_app_user_id" => app_user_id},
        message
      ) do
    with {:ok, _} <- Linear.create_comment(app_user_id, issue_id, message) do
      {:ok, "Replied to issue #{issue_id}"}
    end
  end

  def reply(event, _message) do
    {:error, "Egress.Linear.reply/1 - event not supported: #{inspect(event)}"}
  end
end
