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
  """
  def new(event_data, source, opts \\ []) when is_atom(source) do
    with {:ok, type} <- extract_event_type(event_data, source),
         {:ok, user_id} <- extract_user_id(event_data, source, opts),
         {:ok, repository_external_id} <- extract_repository_id(event_data, source, opts),
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
      data["pull_request"] -> {:ok, "pull_request"}
      data["issue"] -> {:ok, "issue"}
      data["push"] -> {:ok, "push"}
      data["repository"] -> {:ok, "repository"}
      true -> {:error, "Unknown GitHub event type"}
    end
  end

  defp extract_event_type(data, :linear) do
    case data["action"] do
      nil -> {:error, "Missing action field in Linear event"}
      action when is_binary(action) -> {:ok, action}
      _ -> {:error, "Invalid action field in Linear event"}
    end
  end

  defp extract_event_type(data, :slack) do
    cond do
      data["event"]["type"] == "app_mention" ->
        {:ok, "thread_mention"}

      data["event"]["type"] == "message" && data["event"]["channel_type"] == "im" ->
        {:ok, "direct_message"}

      true ->
        {:error, "Unknown Slack event type"}
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
  defp extract_repository_id(data, :github, opts) do
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

  defp extract_repository_id(_data, _source, opts) do
    {:ok, Keyword.get(opts, :repository_external_id)}
  end

  # Extract external IDs for tracking purposes conforming to Agent struct fields
  defp extract_external_ids(data, :github) do
    external_ids = %{}

    external_ids =
      if data["pull_request"] do
        Map.put(external_ids, :github_pull_request_id, data["pull_request"]["id"])
      else
        external_ids
      end

    external_ids =
      if data["issue"] do
        Map.put(external_ids, :github_issue_id, data["issue"]["id"])
      else
        external_ids
      end

    {:ok, external_ids}
  end

  defp extract_external_ids(data, :linear) do
    external_ids = %{}

    external_ids =
      cond do
        # New notification-based format
        data["notification"]["issue"] ->
          Map.put(external_ids, :linear_issue_id, data["notification"]["issue"]["id"])

        # Direct issue format
        data["data"] && data["type"] == "Issue" ->
          Map.put(external_ids, :linear_issue_id, data["data"]["id"])

        # Legacy format
        data["data"]["issue"] ->
          Map.put(external_ids, :linear_issue_id, data["data"]["issue"]["id"])

        true ->
          external_ids
      end

    external_ids =
      cond do
        # New notification-based comment format
        data["notification"]["comment"] ->
          Map.put(external_ids, :linear_comment_id, data["notification"]["comment"]["id"])

        # Legacy comment format
        data["data"]["comment"] ->
          Map.put(external_ids, :linear_comment_id, data["data"]["comment"]["id"])

        true ->
          external_ids
      end

    {:ok, external_ids}
  end

  defp extract_external_ids(data, :slack) do
    external_ids = %{}

    external_ids =
      if data["event"]["ts"] do
        Map.put(external_ids, :slack_thread_id, data["event"]["ts"])
      else
        external_ids
      end

    {:ok, external_ids}
  end

  defp extract_external_ids(_data, :manual) do
    {:ok, %{}}
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
      repository: data["repository"]
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
