defmodule Swarm.Ingress.Event do
  @moduledoc """
  Represents a standardized event from any external source.

  This struct normalizes events from different sources (GitHub, Linear, Slack, Manual)
  into a common format for processing by handlers.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :source, atom(), enforce: true
    field :type, String.t(), enforce: true
    field :raw_data, map(), enforce: true
    field :user_id, integer() | nil
    # Note: repository_external_id is the external repository ID
    field :repository_external_id, integer() | nil
    field :external_ids, map(), default: %{}
    field :context, map(), default: %{}
    field :timestamp, DateTime.t(), default: DateTime.utc_now()
  end

  @doc """
  Creates a new Event struct from raw event data.

  ## Parameters
    - event_data: Raw event data from webhook or manual trigger
    - source: Event source (:github, :linear, :slack, :manual)
    - opts: Additional options that may contain:
      - user_id: Override user identification
      - repository_external_id: Override repository identification
      - context: Additional context for processing

  ## Returns
    - `{:ok, %Event{}}` - Successfully created event
    - `{:error, reason}` - Failed to create event
    - `{:ok, :ignored}` - Event was valid but ignored (e.g., not relevant)
  """
  def new(event_data, source, opts \\ []) when is_atom(source) do
    with {:ok, type} <- extract_event_type(event_data, source),
         {:ok, user_id} <- extract_user_id(event_data, source, opts),
         {:ok, repository_external_id} <-
           extract_repository_external_id(event_data, source, opts),
         {:ok, external_ids} <- extract_external_ids(event_data, source),
         {:ok, context} <- extract_context(event_data, source, opts) do
      event = %__MODULE__{
        source: source,
        type: type,
        raw_data: event_data,
        user_id: user_id,
        repository_external_id: repository_external_id,
        external_ids: external_ids,
        context: context,
        timestamp: DateTime.utc_now()
      }

      {:ok, event}
    end
  end

  # Extract event type based on source
  defp extract_event_type(data, :github) do
    cond do
      data["comment"] && data["issue"] -> {:ok, "issue_comment"}
      data["pull_request"] -> {:ok, "pull_request"}
      data["issue"] -> {:ok, "issue"}
      data["push"] -> {:ok, "push"}
      data["repository"] -> {:ok, "repository"}
      true -> {:ok, :ignored}
    end
  end

  defp extract_event_type(data, :linear) do
    case data["action"] do
      nil -> {:ok, :ignored}
      action when is_binary(action) -> {:ok, action}
      _ -> {:ok, :ignored}
    end
  end

  defp extract_event_type(data, :slack) do
    cond do
      data["event"]["type"] == "app_mention" ->
        {:ok, "thread_mention"}

      data["event"]["type"] == "message" && data["event"]["channel_type"] == "im" ->
        {:ok, "direct_message"}

      true ->
        {:ok, :ignored}
    end
  end

  defp extract_event_type(_data, :manual) do
    {:ok, "agent_spawn_request"}
  end

  # Extract user ID based on source
  defp extract_user_id(_data, _source, opts) when is_list(opts) do
    case Keyword.get(opts, :user_id) do
      nil -> {:ok, nil}
      user_id -> {:ok, user_id}
    end
  end

  # Extract repository ID based on source
  defp extract_repository_external_id(data, :github, opts) do
    case Keyword.get(opts, :repository_external_id) do
      nil ->
        repo_id = get_in(data, ["repository", "id"])

        if repo_id do
          {:ok, "github:#{repo_id}"}
        else
          {:ok, nil}
        end

      repo_id ->
        case repo_id do
          "github:" <> _id -> {:ok, repo_id}
          id -> {:ok, "github:#{id}"}
        end
    end
  end

  defp extract_repository_external_id(_data, _source, opts) do
    {:ok, Keyword.get(opts, :repository_external_id)}
  end

  # Extract external IDs for tracking purposes conforming to Agent struct fields
  defp extract_external_ids(data, :github) do
    %{}
    |> extract_github_installation_id(data)
    |> extract_github_repository_id(data)
    |> extract_github_sender_login(data)
    |> extract_github_pull_request_id(data)
    |> extract_github_pull_request_number(data)
    |> extract_github_pull_request_url(data)
    |> extract_github_issue_id(data)
    |> extract_github_issue_number(data)
    |> extract_github_issue_url(data)
    |> extract_github_comment_id(data)
    |> then(&{:ok, &1})
  end

  defp extract_external_ids(data, :linear) do
    %{}
    |> extract_linear_issue_id(data)
    |> extract_linear_comment_id(data)
    |> extract_linear_parent_comment_id(data)
    |> extract_linear_parent_comment_user_id(data)
    |> extract_linear_document_id(data)
    |> extract_linear_team_id(data)
    |> extract_linear_project_id(data)
    |> extract_linear_app_user_id(data)
    |> then(&{:ok, &1})
  end

  defp extract_external_ids(data, :slack) do
    external_ids =
      if data["event"]["ts"] do
        Map.put(%{}, "slack_thread_id", data["event"]["ts"])
      else
        %{}
      end

    {:ok, external_ids}
  end

  defp extract_external_ids(_data, :manual) do
    {:ok, %{}}
  end

  defp extract_github_installation_id(external_ids, data) do
    if data["installation"] && data["installation"]["id"] do
      Map.put(external_ids, "github_installation_id", data["installation"]["id"])
    else
      external_ids
    end
  end

  defp extract_github_repository_id(external_ids, data) do
    if data["repository"] && data["repository"]["id"] do
      Map.put(external_ids, "github_repository_id", data["repository"]["id"])
    else
      external_ids
    end
  end

  defp extract_github_sender_login(external_ids, data) do
    if data["sender"] && data["sender"]["login"] do
      Map.put(external_ids, "github_sender_login", data["sender"]["login"])
    else
      external_ids
    end
  end

  defp extract_github_pull_request_id(external_ids, data) do
    if data["pull_request"] do
      Map.put(external_ids, "github_pull_request_id", data["pull_request"]["id"])
    else
      external_ids
    end
  end

  defp extract_github_pull_request_number(external_ids, data) do
    if data["pull_request"] do
      Map.put(external_ids, "github_pull_request_number", data["pull_request"]["number"])
    else
      external_ids
    end
  end

  defp extract_github_pull_request_url(external_ids, data) do
    if data["pull_request"] do
      Map.put(external_ids, "github_pull_request_url", data["pull_request"]["html_url"])
    else
      external_ids
    end
  end

  defp extract_github_issue_id(external_ids, data) do
    if data["issue"] do
      Map.put(external_ids, "github_issue_id", data["issue"]["id"])
    else
      external_ids
    end
  end

  defp extract_github_issue_number(external_ids, data) do
    if data["issue"] do
      Map.put(external_ids, "github_issue_number", data["issue"]["number"])
    else
      external_ids
    end
  end

  defp extract_github_issue_url(external_ids, data) do
    if data["issue"] do
      Map.put(external_ids, "github_issue_url", data["issue"]["html_url"])
    else
      external_ids
    end
  end

  defp extract_github_comment_id(external_ids, data) do
    if data["comment"] do
      Map.put(external_ids, "github_comment_id", data["comment"]["id"])
    else
      external_ids
    end
  end

  defp extract_linear_issue_id(external_ids, data) do
    cond do
      # New notification-based format
      data["notification"]["issue"] ->
        external_ids
        |> Map.put("linear_issue_id", data["notification"]["issue"]["id"])
        |> Map.put("linear_issue_identifier", data["notification"]["issue"]["identifier"])
        |> Map.put("linear_issue_url", data["notification"]["issue"]["url"])

      # Direct issue format
      data["data"] && data["type"] == "Issue" ->
        external_ids
        |> Map.put("linear_issue_id", data["data"]["id"])
        |> Map.put("linear_issue_identifier", data["data"]["identifier"])
        |> Map.put("linear_issue_url", data["data"]["url"])

      # Legacy format
      data["data"]["issue"] ->
        external_ids
        |> Map.put("linear_issue_id", data["data"]["issue"]["id"])
        |> Map.put("linear_issue_identifier", data["data"]["issue"]["identifier"])
        |> Map.put("linear_issue_url", data["data"]["issue"]["url"])

      true ->
        external_ids
    end
  end

  defp extract_linear_comment_id(external_ids, data) do
    cond do
      # New notification-based comment format
      data["notification"]["comment"] ->
        Map.put(external_ids, "linear_comment_id", data["notification"]["comment"]["id"])

      # Legacy comment format
      data["data"]["comment"] ->
        Map.put(external_ids, "linear_comment_id", data["data"]["comment"]["id"])

      true ->
        external_ids
    end
  end

  defp extract_linear_parent_comment_id(external_ids, data) do
    if data["notification"]["parentCommentId"] do
      Map.put(external_ids, "linear_parent_comment_id", data["notification"]["parentCommentId"])
    else
      external_ids
    end
  end

  defp extract_linear_parent_comment_user_id(external_ids, data) do
    if data["notification"]["parentComment"] do
      Map.put(
        external_ids,
        "linear_parent_comment_user_id",
        data["notification"]["parentComment"]["userId"]
      )
    else
      external_ids
    end
  end

  defp extract_linear_document_id(external_ids, data) do
    cond do
      # New notification-based document format
      data["notification"]["document"] ->
        Map.put(external_ids, "linear_document_id", data["notification"]["document"]["id"])

      # Alternative document ID format
      data["notification"]["documentId"] ->
        Map.put(external_ids, "linear_document_id", data["notification"]["documentId"])

      true ->
        external_ids
    end
  end

  defp extract_linear_team_id(external_ids, data) do
    cond do
      data["notification"] && data["notification"]["teamId"] ->
        Map.put(external_ids, "linear_team_id", data["notification"]["teamId"])

      data["notification"] && data["notification"]["issue"]["teamId"] ->
        Map.put(external_ids, "linear_team_id", data["notification"]["issue"]["teamId"])

      true ->
        external_ids
    end
  end

  defp extract_linear_project_id(external_ids, data) do
    if data["notification"] && data["notification"]["document"] &&
         data["notification"]["document"]["projectId"] do
      Map.put(external_ids, "linear_project_id", data["notification"]["document"]["projectId"])
    else
      external_ids
    end
  end

  defp extract_linear_app_user_id(external_ids, data) do
    if data["appUserId"] do
      Map.put(external_ids, "linear_app_user_id", data["appUserId"])
    else
      external_ids
    end
  end

  # Extract context information
  defp extract_context(data, source, opts) do
    base_context = Keyword.get(opts, :context, %{})

    source_context =
      case source do
        :github -> extract_github_context(data)
        :linear -> extract_linear_context(data)
        :slack -> extract_slack_context(data)
        :manual -> extract_manual_context(data)
      end

    {:ok, Map.merge(base_context, source_context)}
  end

  defp extract_github_context(data) do
    %{
      action: data["action"],
      sender: data["sender"],
      repository: data["repository"],
      issue: data["issue"],
      comment: data["comment"],
      installation: data["installation"]
    }
  end

  defp extract_linear_context(data) do
    base_context = %{
      action: data["action"],
      actor: data["actor"],
      data: data["data"]
    }

    # Add notification data if present (new webhook format)
    context_with_notification =
      if data["notification"] do
        Map.put(base_context, :notification, data["notification"])
        |> Map.put(:actor, data["notification"]["actor"])
      else
        base_context
      end

    # Add organization and webhook metadata
    context_with_notification
    |> Map.put(:organization_id, data["organizationId"])
    |> Map.put(:webhook_id, data["webhookId"])
    |> Map.put(:webhook_timestamp, data["webhookTimestamp"])
  end

  defp extract_slack_context(data) do
    %{
      event: data["event"],
      team_id: data["team_id"]
    }
  end

  defp extract_manual_context(data) do
    data
  end
end
