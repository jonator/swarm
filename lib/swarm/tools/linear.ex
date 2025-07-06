defmodule Swarm.Tools.Linear do
  @moduledoc false

  require Logger
  alias LangChain.Function
  alias LangChain.FunctionParam
  alias Swarm.Services.Linear

  def all_tools(_mode \\ :read_write) do
    [acknowledge(), reply(), edit_comment(), update_issue_description()]
  end

  def acknowledge do
    Function.new!(%{
      name: "acknowledge",
      description: "Acknowledges a Linear issue or comment with an emoji reaction.",
      parameters: [],
      function: fn _args, %{"agent" => %{:external_ids => external_ids}} ->
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
      function: fn %{"message" => message}, %{"agent" => %{:external_ids => external_ids}} ->
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

  def edit_comment do
    Function.new!(%{
      name: "edit_comment",
      description: "Edits an existing Linear comment.",
      parameters: [
        FunctionParam.new!(%{
          name: "message",
          type: :string,
          description: "The new body of the comment.",
          required: true
        })
      ],
      function: fn %{"message" => message}, %{"agent" => %{:external_ids => external_ids}} ->
        case external_ids do
          %{"linear_comment_id" => comment_id, "linear_app_user_id" => app_user_id} ->
            case Linear.mutate_comment(app_user_id, comment_id, message) do
              {:ok, _} ->
                {:ok, "Edited comment #{comment_id}"}

              {:error, reason} ->
                {:error, "Failed to edit comment #{comment_id}: #{inspect(reason)}"}
            end

          _ ->
            Logger.error(
              "Linear.edit_comment/1 - required context not available: #{inspect(external_ids)}"
            )

            {:error, "required context not available to edit comment in linear"}
        end
      end
    })
  end

  def update_issue_description do
    Function.new!(%{
      name: "update_issue_description",
      description: "Updates the description of a Linear issue.",
      parameters: [
        FunctionParam.new!(%{
          name: "description",
          type: :string,
          description: "The new description for the issue.",
          required: true
        })
      ],
      function: fn %{"description" => description},
                   %{"agent" => %{:external_ids => external_ids}} ->
        case external_ids do
          %{"linear_issue_id" => issue_id, "linear_app_user_id" => app_user_id} ->
            case Linear.update_issue_description(app_user_id, issue_id, description) do
              {:ok, _} ->
                {:ok, "Updated description for issue #{issue_id}"}

              {:error, reason} ->
                {:error, "Failed to update description for issue #{issue_id}: #{inspect(reason)}"}
            end

          _ ->
            Logger.error(
              "Linear.update_issue_description/1 - required context not available: #{inspect(external_ids)}"
            )

            {:error, "required context not available to update issue description in linear"}
        end
      end
    })
  end
end
