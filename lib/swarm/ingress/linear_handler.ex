defmodule Swarm.Ingress.LinearHandler do
  @moduledoc """
  Handles Linear webhook events and generates agent attributes.

  This handler processes various Linear event types:
  - Issue assigned to @swarm
  - @swarm mentioned in comments
  - @swarm mentioned in issue descriptions
  - @swarm mentioned in documents
  """

  require Logger

  alias Swarm.Ingress.Event
  alias Swarm.Ingress.Permissions
  alias Swarm.Services.Linear

  @doc """
  Handles a Linear event and generates agent attributes.

  ## Parameters
    - event: Standardized event struct from Linear webhook

  ## Returns
    - `{:ok, agent_attrs}` - Successfully created agent attributes
    - `{:ok, :ignored}` - Event was valid but not actionable
    - `{:error, reason}` - Event processing failed
  """
  def handle(%Event{source: :linear} = event) do
    Logger.info("Processing Linear event: #{event.type}")

    # Check if event is relevant first
    if relevant_event?(event) do
      with {:ok, user, repository, _organization} <- Permissions.validate_user_access(event) do
        build_agent_attributes(event, user, repository)
      end
    else
      {:ok, :ignored}
    end
  end

  def handle(%Event{source: other_source}) do
    {:error, "LinearHandler received non-Linear event: #{other_source}"}
  end

  def relevant_event?(%Event{type: "issueAssignedToYou"}), do: true
  def relevant_event?(%Event{type: "issueCommentMention"}), do: true
  def relevant_event?(%Event{type: "issueMention"}), do: true
  def relevant_event?(%Event{type: "documentMention"}), do: true
  def relevant_event?(_), do: false

  @doc """
  Builds agent attributes from the Linear event data.
  """
  def build_agent_attributes(
        %Event{type: type, external_ids: external_ids} = event,
        user,
        repository
      ) do
    base_attrs = %{
      user_id: user.id,
      repository: repository,
      source: :linear
    }

    type_specific_attrs =
      case type do
        "issueAssignedToYou" -> build_issue_assigned_attrs(event)
        "issueCommentMention" -> build_issue_comment_mention_attrs(event)
        "issueMention" -> build_issue_description_mention_attrs(event)
        "documentMention" -> build_document_mention_attrs(event)
        _ -> %{}
      end

    attrs = Map.merge(base_attrs, type_specific_attrs)
    attrs = Map.put(attrs, :external_ids, external_ids)

    {:ok, attrs}
  end

  defp build_issue_assigned_attrs(%Event{context: context, external_ids: external_ids}) do
    issue = get_issue_from_context(context)
    context_text = build_issue_context(issue, external_ids, "assigned")

    %{
      context: context_text
    }
  end

  defp build_issue_comment_mention_attrs(%Event{context: context, external_ids: external_ids}) do
    comment = get_comment_from_context(context)
    issue = get_issue_from_context(context)

    context_text =
      if external_ids["linear_parent_comment_id"] do
        build_issue_context(
          issue,
          external_ids,
          "mentioned in reply comment #{comment["id"]} (parent comment ID: #{external_ids["linear_parent_comment_id"]})"
        )
      else
        build_issue_context(issue, external_ids, "mentioned in comment #{comment["id"]}")
      end

    %{
      context: context_text
    }
  end

  defp build_issue_description_mention_attrs(%Event{context: context, external_ids: external_ids}) do
    issue = get_issue_from_context(context)
    context_text = build_issue_context(issue, external_ids, "mentioned in description")

    %{
      context: context_text
    }
  end

  defp build_document_mention_attrs(%Event{context: context, external_ids: external_ids}) do
    document = get_in(context, [:notification, "document"])
    document_content = fetch_document_content(external_ids)

    context_text = """
    Linear Document Mention: #{document["title"]}

    @swarm was mentioned in this document.

    Document URL: #{document["url"] || "No URL available"}

    Document Content:
    #{document_content}
    """

    %{
      context: context_text
    }
  end

  defp fetch_document_content(external_ids) do
    document_id = external_ids["linear_document_id"]
    app_user_id = external_ids["linear_app_user_id"]

    if document_id && app_user_id do
      fetch_document_from_api(app_user_id, document_id)
    else
      "Document content unavailable - missing document ID or app user ID"
    end
  end

  defp fetch_document_from_api(app_user_id, document_id) do
    case Linear.document(app_user_id, document_id) do
      {:ok, %{"document" => doc_data}} ->
        doc_data["content"] || "Document content unavailable"

      {:error, _reason} ->
        "Unable to fetch document content - API error"

      {:unauthorized, _reason} ->
        "Unable to fetch document content - unauthorized"

      {:ok, %{status: status}} when status != 200 ->
        "Unable to fetch document content - HTTP #{status}"

      _other ->
        "Unable to fetch document content - unknown error"
    end
  end

  # Helper functions for event analysis

  defp get_issue_from_context(context) do
    cond do
      # New notification format
      context[:notification] && context[:notification]["issue"] ->
        context[:notification]["issue"]

      # Direct issue data format
      context[:data] && is_map(context[:data]) && context[:data]["id"] ->
        context[:data]

      # Legacy format
      context[:data] && context[:data]["issue"] ->
        context[:data]["issue"]

      true ->
        %{}
    end
  end

  defp get_comment_from_context(context) do
    cond do
      # New notification format
      context[:notification] && context[:notification]["comment"] ->
        context[:notification]["comment"]

      # Legacy format
      context[:data] && context[:data]["comment"] ->
        context[:data]["comment"]

      true ->
        %{}
    end
  end

  defp build_issue_context(issue, external_ids, action) do
    description = get_issue_description(issue, external_ids)
    comment_threads = get_issue_comment_threads(issue, external_ids)

    """
    Linear Issue #{action} (Issue ID: #{issue["id"]}): #{issue["title"]}

    Description:
    #{description}

    Comment Threads:
    #{comment_threads}

    Priority: #{issue["priority"] || "No priority set"}
    Team: #{get_in(issue, ["team", "name"]) || "Unknown"}
    """
  end

  defp get_issue_description(issue, external_ids) do
    case issue["description"] do
      nil -> fetch_issue_description_from_api(external_ids, issue["id"])
      description -> description
    end
  end

  defp fetch_issue_description_from_api(external_ids, issue_id) do
    case Linear.issue(external_ids["linear_app_user_id"], issue_id) do
      {:ok, %{"issue" => %{"documentContent" => %{"content" => content}}}} ->
        content

      {:error, reason} ->
        Logger.error("Failed to fetch issue description - API error: #{inspect(reason)}")
        "Unable to fetch issue description - API error"

      {:unauthorized, reason} ->
        Logger.error("Failed to fetch issue description - unauthorized: #{inspect(reason)}")
        "Unable to fetch issue description - unauthorized"

      {:ok, %{status: status}} when status != 200 ->
        "Unable to fetch issue description - HTTP #{status}"

      _ ->
        "No description provided"
    end
  end

  defp get_issue_comment_threads(issue, external_ids) do
    case Linear.issue_comment_threads(external_ids["linear_app_user_id"], issue["id"]) do
      {:ok, %{"issue" => %{"comments" => %{"nodes" => comments}}}} ->
        format_comment_threads(comments)

      {:error, _reason} ->
        "Unable to fetch issue comment threads - API error"

      {:unauthorized, _reason} ->
        "Unable to fetch issue comment threads - unauthorized"

      {:ok, %{status: status}} when status != 200 ->
        "Unable to fetch issue comment threads - HTTP #{status}"

      _other ->
        "Unable to fetch issue comment threads - unknown error"
    end
  end

  defp format_comment_threads([]), do: "No comments yet"

  defp format_comment_threads(comments) do
    Enum.map_join(comments, "\n\n", &format_comment/1)
  end

  defp format_comment(%{
         "id" => id,
         "body" => body,
         "user" => %{"displayName" => display_name},
         "children" => %{"nodes" => children},
         "createdAt" => created_at
       }) do
    formatted_comment = "- (#{id}) #{display_name} [#{format_datetime(created_at)}]: #{body}"

    case children do
      [] ->
        formatted_comment

      replies ->
        reply_text =
          Enum.map_join(replies, "\n", fn %{
                                            "id" => reply_id,
                                            "body" => reply_body,
                                            "user" => %{"displayName" => reply_display_name},
                                            "createdAt" => reply_created_at
                                          } ->
            "  - (#{reply_id}) #{reply_display_name} [#{format_datetime(reply_created_at)}]: #{reply_body}"
          end)

        formatted_comment <> "\n" <> reply_text
    end
  end

  defp format_comment(%{
         "id" => id,
         "body" => body,
         "user" => %{"displayName" => display_name},
         "createdAt" => created_at
       }),
       do: "- (#{id}) #{display_name} [#{format_datetime(created_at)}]: #{body}"

  defp format_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} ->
        Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")

      _ ->
        datetime_string
    end
  end
end
