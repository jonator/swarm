defmodule Swarm.Ingress.LinearHandler do
  @moduledoc """
  Handles Linear webhook events and generates agent attributes.

  This handler processes various Linear event types:
  - Issue assigned to @swarm
  - @swarm mentioned in comments
  - @swarm mentioned in issue descriptions
  - @swarm mentioned in documents

  The handler validates user permissions and builds appropriate agent attributes
  for each event type.
  """

  require Logger

  alias Swarm.Ingress.Event
  alias Swarm.Ingress.Permissions
  alias Swarm.Services.Linear

  @type event_result :: {:ok, map()} | {:ok, :ignored} | {:error, binary()}

  # Event Types
  @issue_assigned "issueAssignedToYou"
  @issue_comment_mention "issueCommentMention"
  @issue_new_comment "issueNewComment"
  @issue_mention "issueMention"
  @document_mention "documentMention"

  @doc """
  Handles a Linear event and generates agent attributes.

  ## Parameters
    - event: Standardized event struct from Linear webhook

  ## Returns
    - `{:ok, agent_attrs}` - Successfully created agent attributes
    - `{:ok, :ignored}` - Event was valid but not actionable
    - `{:error, reason}` - Event processing failed
  """
  @spec handle(Event.t()) :: event_result()
  def handle(%Event{source: :linear} = event) do
    Logger.info("Processing Linear event: #{event.type}")

    if relevant_event?(event) do
      process_relevant_event(event)
    else
      {:ok, :ignored}
    end
  end

  def handle(%Event{source: other_source}) do
    {:error, "LinearHandler received non-Linear event: #{other_source}"}
  end

  # Event Relevance Checks

  @doc """
  Determines if a Linear event is relevant and should be processed.
  """
  @spec relevant_event?(Event.t()) :: boolean()
  def relevant_event?(%Event{type: @issue_assigned}), do: true
  def relevant_event?(%Event{type: @issue_comment_mention}), do: true
  def relevant_event?(%Event{type: @issue_mention}), do: true
  def relevant_event?(%Event{type: @document_mention}), do: true
  
  def relevant_event?(%Event{type: @issue_new_comment, external_ids: external_ids}) do
    # Only process if parent comment was from Swarm AI
    is_reply_to_swarm_comment?(external_ids)
  end
  
  def relevant_event?(_), do: false

  # Event Processing

  @spec process_relevant_event(Event.t()) :: event_result()
  defp process_relevant_event(event) do
    with {:ok, user, repository, _organization} <- Permissions.validate_user_access(event) do
      build_agent_attributes(event, user, repository)
    end
  end

  @doc """
  Builds agent attributes from the Linear event data.
  """
  @spec build_agent_attributes(Event.t(), any(), any()) :: {:ok, map()}
  def build_agent_attributes(%Event{external_ids: external_ids} = event, user, repository) do
    base_attrs = build_base_attributes(user, repository)
    type_specific_attrs = build_type_specific_attributes(event)
    
    attrs = 
      base_attrs
      |> Map.merge(type_specific_attrs)
      |> Map.put(:external_ids, external_ids)

    {:ok, attrs}
  end

  # Attribute Building

  @spec build_base_attributes(any(), any()) :: map()
  defp build_base_attributes(user, repository) do
    %{
      user_id: user.id,
      repository: repository,
      source: :linear
    }
  end

  @spec build_type_specific_attributes(Event.t()) :: map()
  defp build_type_specific_attributes(%Event{type: @issue_assigned} = event) do
    build_issue_assigned_attrs(event)
  end

  defp build_type_specific_attributes(%Event{type: @issue_comment_mention} = event) do
    build_issue_comment_attrs(event)
  end

  defp build_type_specific_attributes(%Event{type: @issue_new_comment} = event) do
    build_issue_comment_attrs(event)
  end

  defp build_type_specific_attributes(%Event{type: @issue_mention} = event) do
    build_issue_description_mention_attrs(event)
  end

  defp build_type_specific_attributes(%Event{type: @document_mention} = event) do
    build_document_mention_attrs(event)
  end

  defp build_type_specific_attributes(_event), do: %{}

  # Specific Attribute Builders

  @spec build_issue_assigned_attrs(Event.t()) :: map()
  defp build_issue_assigned_attrs(%Event{context: context, external_ids: external_ids}) do
    issue = extract_issue_from_context(context)
    context_text = build_issue_context(issue, external_ids, "assigned")

    %{context: context_text}
  end

  @spec build_issue_comment_attrs(Event.t()) :: map()
  defp build_issue_comment_attrs(%Event{context: context, external_ids: external_ids}) do
    comment = extract_comment_from_context(context)
    issue = extract_issue_from_context(context)

    context_text = determine_comment_context_type(issue, comment, external_ids)

    %{context: context_text}
  end

  @spec build_issue_description_mention_attrs(Event.t()) :: map()
  defp build_issue_description_mention_attrs(%Event{context: context, external_ids: external_ids}) do
    issue = extract_issue_from_context(context)
    context_text = build_issue_context(issue, external_ids, "mentioned in description")

    %{context: context_text}
  end

  @spec build_document_mention_attrs(Event.t()) :: map()
  defp build_document_mention_attrs(%Event{context: context, external_ids: external_ids}) do
    document = extract_document_from_context(context)
    document_content = fetch_document_content(external_ids)

    context_text = build_document_context(document, document_content)

    %{context: context_text}
  end

  # Context Extraction

  @spec extract_issue_from_context(map()) :: map()
  defp extract_issue_from_context(context) do
    cond do
      # New notification format
      get_in(context, [:notification, "issue"]) ->
        context[:notification]["issue"]

      # Direct issue data format
      context[:data] && is_map(context[:data]) && context[:data]["id"] ->
        context[:data]

      # Legacy format
      get_in(context, [:data, "issue"]) ->
        context[:data]["issue"]

      true ->
        %{}
    end
  end

  @spec extract_comment_from_context(map()) :: map()
  defp extract_comment_from_context(context) do
    cond do
      # New notification format
      get_in(context, [:notification, "comment"]) ->
        context[:notification]["comment"]

      # Legacy format
      get_in(context, [:data, "comment"]) ->
        context[:data]["comment"]

      true ->
        %{}
    end
  end

  @spec extract_document_from_context(map()) :: map()
  defp extract_document_from_context(context) do
    get_in(context, [:notification, "document"]) || %{}
  end

  # Context Building

  @spec determine_comment_context_type(map(), map(), map()) :: binary()
  defp determine_comment_context_type(issue, comment, external_ids) do
    parent_comment_id = external_ids["linear_parent_comment_id"]

    cond do
      parent_comment_id && is_reply_to_swarm_comment?(external_ids) ->
        build_swarm_comment_reply_context(issue, external_ids, comment)

      parent_comment_id ->
        build_comment_reply_context(issue, external_ids, comment)

      true ->
        build_direct_comment_mention_context(issue, external_ids, comment)
    end
  end

  @spec build_swarm_comment_reply_context(map(), map(), map()) :: binary()
  defp build_swarm_comment_reply_context(issue, external_ids, comment) do
    description = get_issue_description(issue, external_ids)
    parent_comment_id = external_ids["linear_parent_comment_id"]

    """
    Linear Issue Event: Swarm AI comment replied to in comment (Swarm AI original comment ID: #{parent_comment_id}) (Issue ID: #{issue["id"]}): #{issue["title"]}

    Latest request (this likely means the Swarm AI PARENT COMMENT from Swarm AI (#{parent_comment_id}) NEEDS TO BE UPDATED/EDITED and that you NEED TO SPAWN A RESEARCH AGENT):
    Reply to Swarm AI: #{comment["body"]}

    Description:
    #{description}

    Priority: #{issue["priority"] || "No priority set"}
    Team: #{get_team_name(issue)}
    """
  end

  @spec build_comment_reply_context(map(), map(), map()) :: binary()
  defp build_comment_reply_context(issue, external_ids, comment) do
    description = get_issue_description(issue, external_ids)
    comment_threads = get_issue_comment_threads(issue, external_ids)
    parent_comment_id = external_ids["linear_parent_comment_id"]

    """
    Linear Issue mentioned in reply comment #{comment["id"]} (parent comment ID: #{parent_comment_id}) (Issue ID: #{issue["id"]}): #{issue["title"]}

    New comment:
    (#{comment["id"]}): #{comment["body"]}

    Description:
    #{description}

    Comment Threads:
    #{comment_threads}

    Priority: #{issue["priority"] || "No priority set"}
    Team: #{get_team_name(issue)}
    """
  end

  @spec build_direct_comment_mention_context(map(), map(), map()) :: binary()
  defp build_direct_comment_mention_context(issue, external_ids, comment) do
    description = get_issue_description(issue, external_ids)
    comment_threads = get_issue_comment_threads(issue, external_ids)

    """
    Linear Issue mentioned in comment #{comment["id"]} (Issue ID: #{issue["id"]}): #{issue["title"]}

    New comment:
    (#{comment["id"]}): #{comment["body"]}

    Description:
    #{description}

    Comment Threads:
    #{comment_threads}

    Priority: #{issue["priority"] || "No priority set"}
    Team: #{get_team_name(issue)}
    """
  end

  @spec build_issue_context(map(), map(), binary()) :: binary()
  defp build_issue_context(issue, external_ids, action) do
    description = get_issue_description(issue, external_ids)
    comment_threads = get_issue_comment_threads(issue, external_ids)

    """
    Linear Issue #{action} (Issue ID: #{issue["id"]}): #{issue["title"]}

    Description:
    #{description}

    Comment Threads:
    #{comment_threads}
    """
  end

  @spec build_document_context(map(), binary()) :: binary()
  defp build_document_context(document, document_content) do
    document_url = document["url"] || "No URL available"

    """
    Linear Document Mention: #{document["title"]}

    @swarm was mentioned in this document.

    Document URL: #{document_url}

    Document Content:
    #{document_content}
    """
  end

  # Helper Functions

  @spec is_reply_to_swarm_comment?(map()) :: boolean()
  defp is_reply_to_swarm_comment?(external_ids) do
    external_ids["linear_parent_comment_user_id"] == external_ids["linear_app_user_id"]
  end

  @spec get_team_name(map()) :: binary()
  defp get_team_name(issue) do
    get_in(issue, ["team", "name"]) || "Unknown"
  end

  @spec get_issue_description(map(), map()) :: binary()
  defp get_issue_description(issue, external_ids) do
    case issue["description"] do
      nil -> fetch_issue_description_from_api(external_ids, issue["id"])
      description -> description
    end
  end

  @spec fetch_issue_description_from_api(map(), binary()) :: binary()
  defp fetch_issue_description_from_api(external_ids, issue_id) do
    app_user_id = external_ids["linear_app_user_id"]

    case Linear.issue(app_user_id, issue_id) do
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

  @spec get_issue_comment_threads(map(), map()) :: binary()
  defp get_issue_comment_threads(issue, external_ids) do
    app_user_id = external_ids["linear_app_user_id"]
    issue_id = issue["id"]

    case Linear.issue_comment_threads(app_user_id, issue_id) do
      {:ok, %{"issue" => %{"comments" => %{"nodes" => comments}}}} ->
        format_comment_threads(comments)

      {:error, reason} ->
        Logger.error("Failed to fetch issue comment threads - API error: #{inspect(reason)}")
        "Unable to fetch issue comment threads - API error"

      {:unauthorized, reason} ->
        Logger.error("Failed to fetch issue comment threads - unauthorized: #{inspect(reason)}")
        "Unable to fetch issue comment threads - unauthorized"

      {:ok, %{status: status}} when status != 200 ->
        Logger.error("Failed to fetch issue comment threads - HTTP #{status}")
        "Unable to fetch issue comment threads - HTTP #{status}"

      other ->
        Logger.error("Failed to fetch issue comment threads - unknown error: #{inspect(other)}")
        "Unable to fetch issue comment threads - unknown error"
    end
  end

  @spec fetch_document_content(map()) :: binary()
  defp fetch_document_content(external_ids) do
    document_id = external_ids["linear_document_id"]
    app_user_id = external_ids["linear_app_user_id"]

    if document_id && app_user_id do
      fetch_document_from_api(app_user_id, document_id)
    else
      "Document content unavailable - missing document ID or app user ID"
    end
  end

  @spec fetch_document_from_api(binary(), binary()) :: binary()
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

  # Comment Formatting

  @spec format_comment_threads([map()]) :: binary()
  defp format_comment_threads([]), do: "No comments yet"

  defp format_comment_threads(comments) do
    Enum.map_join(comments, "\n\n", &format_comment/1)
  end

  @spec format_comment(map()) :: binary()
  defp format_comment(comment) do
    base_comment = format_base_comment(comment)
    replies = format_comment_replies(comment)

    case replies do
      "" -> base_comment
      reply_text -> base_comment <> "\n" <> reply_text
    end
  end

  @spec format_base_comment(map()) :: binary()
  defp format_base_comment(%{
    "id" => id,
    "body" => body,
    "user" => %{"displayName" => display_name},
    "createdAt" => created_at
  }) do
    "- (#{id}) #{display_name} [#{format_datetime(created_at)}]: #{body}"
  end

  @spec format_comment_replies(map()) :: binary()
  defp format_comment_replies(%{"children" => %{"nodes" => children}}) when is_list(children) do
    Enum.map_join(children, "\n", &format_reply/1)
  end

  defp format_comment_replies(_), do: ""

  @spec format_reply(map()) :: binary()
  defp format_reply(%{
    "id" => reply_id,
    "body" => reply_body,
    "user" => %{"displayName" => reply_display_name},
    "createdAt" => reply_created_at
  }) do
    "  - (#{reply_id}) #{reply_display_name} [#{format_datetime(reply_created_at)}]: #{reply_body}"
  end

  @spec format_datetime(binary()) :: binary()
  defp format_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} ->
        Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")

      _ ->
        datetime_string
    end
  end
end