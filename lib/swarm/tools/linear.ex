defmodule Swarm.Tools.Linear do
  @moduledoc false

  require Logger
  alias LangChain.Function
  alias LangChain.FunctionParam
  alias Swarm.Services.Linear

  def all_tools(_mode \\ :read_write) do
    [acknowledge(), reply()]
  end

  def acknowledge do
    Function.new!(%{
      name: "acknowledge",
      description: "Acknowledges a Linear issue or comment with an emoji reaction.",
      parameters: [],
      function: fn _args, %{"external_ids" => external_ids} ->
        case external_ids do
          %{
            "linear_issue_id" => _issue_id,
            "linear_app_user_id" => app_user_id,
            "linear_comment_id" => comment_id
          } ->
            with {:ok, _} <- Linear.comment_reaction(app_user_id, comment_id, "eyes") do
              {:ok, "Acknowledged comment #{comment_id}, with emoji eyes"}
            end

          %{"linear_issue_id" => issue_id, "linear_app_user_id" => app_user_id} ->
            with {:ok, _} <- Linear.issue_reaction(app_user_id, issue_id, "eyes") do
              {:ok, "Acknowledged issue #{issue_id}, with emoji eyes"}
            end

          _ ->
            Logger.error(
              "Linear.acknowledge/1 - required context not available: #{inspect(external_ids)}"
            )

            {:error, "required context not available to acknowledge in linear"}
        end
      end
    })
  end

  def reply do
    Function.new!(%{
      name: "reply",
      description: "Replies to a Linear issue or comment.",
      parameters: [
        FunctionParam.new!(%{
          name: "message",
          type: :string,
          description: "The message to send as a reply.",
          required: true
        })
      ],
      function: fn %{"message" => message}, %{"external_ids" => external_ids} ->
        case external_ids do
          %{
            "linear_issue_id" => issue_id,
            "linear_app_user_id" => app_user_id,
            "linear_parent_comment_id" => parent_comment_id
          } ->
            with {:ok, _} <-
                   Linear.create_comment(app_user_id, issue_id, message, parent_comment_id) do
              {:ok, "Replied to issue #{issue_id} parent comment #{parent_comment_id}"}
            end

          %{"linear_issue_id" => issue_id, "linear_app_user_id" => app_user_id} ->
            with {:ok, _} <- Linear.create_comment(app_user_id, issue_id, message) do
              {:ok, "Replied to issue #{issue_id}"}
            end

          _ ->
            Logger.error(
              "Linear.reply/1 - required context not available: #{inspect(external_ids)}"
            )

            {:error, "required context not available to reply to linear"}
        end
      end
    })
  end
end
