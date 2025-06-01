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
  alias Swarm.Repositories
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
      with {:ok, user} <- Permissions.validate_user_access(event),
           {:ok, repository} <- find_repository_for_linear_event(user, event),
           {:ok, agent_attrs} <- build_agent_attributes(event, user, repository) do
        {:ok, agent_attrs}
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
  Finds the repository associated with a Linear event.

  Linear events need to be mapped to repositories, which can be done through:
  1. Linear team external IDs stored in repository records
  2. Project associations
  3. Manual configuration
  """
  def find_repository_for_linear_event(user, %Event{type: type, external_ids: external_ids}) do
    case external_ids[:linear_team_id] do
      nil ->
        if type == "documentMention" && external_ids[:linear_project_id] do
          find_repository_by_project_id(
            user,
            external_ids[:linear_app_user_id],
            external_ids[:linear_project_id]
          )
        else
          {:error, "No team information found in Linear event"}
        end

      team_id ->
        find_repository_by_team_id(user, team_id)
    end
  end

  defp find_repository_by_team_id(user, team_id) do
    # Look for repositories that have this Linear team ID in their external IDs
    case Repositories.list_repositories(user) do
      [] ->
        {:error, "No repositories found for user"}

      repositories ->
        matching_repo =
          Enum.find(repositories, fn repo ->
            team_id in (repo.linear_team_external_ids || [])
          end)

        case matching_repo do
          nil ->
            {:error, "No repository found with Linear team ID: #{team_id}"}

          repository ->
            {:ok, repository}
        end
    end
  end

  defp find_repository_by_project_id(user, workspace_id, project_id) do
    case Linear.project(workspace_id, project_id) do
      {:ok, %{"project" => %{"teams" => %{"nodes" => teams}}}} ->
        case teams do
          [] ->
            {:error,
             "No teams available for finding repository with Linear project ID: #{project_id}"}

          [team] ->
            find_repository_by_team_id(user, team["id"])

          [team | _] ->
            Logger.warning(
              "Multiple teams available for finding repository with Linear project ID: #{project_id}, using first team: #{team["id"]}"
            )

            find_repository_by_team_id(user, team["id"])
        end

      {:error, _reason} ->
        {:error, "No repository found with Linear project ID: #{project_id}"}
    end
  end

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
        "issueCommentMention" -> build_comment_mention_attrs(event)
        "issueMention" -> build_description_mention_attrs(event)
        "documentMention" -> build_document_mention_attrs(event)
        _ -> %{}
      end

    attrs = Map.merge(base_attrs, type_specific_attrs)
    attrs = Map.merge(attrs, external_ids)

    {:ok, attrs}
  end

  defp build_issue_assigned_attrs(%Event{context: context}) do
    issue = get_issue_from_context(context)
    context_text = build_issue_context(issue, "assigned")

    %{
      context: context_text
    }
  end

  defp build_comment_mention_attrs(%Event{context: context}) do
    comment = get_comment_from_context(context)
    issue = get_issue_from_context(context)

    context_text = """
    Linear Comment Mention in Issue: #{issue["title"]}

    Comment: #{comment["body"]}

    Issue Description:
    #{issue["description"] || "No description provided"}

    Issue URL: #{issue["url"]}
    """

    %{
      context: context_text
    }
  end

  defp build_description_mention_attrs(%Event{context: context}) do
    issue = get_issue_from_context(context)
    context_text = build_issue_context(issue, "mentioned in description")

    %{
      context: context_text
    }
  end

  defp build_document_mention_attrs(%Event{context: context, external_ids: external_ids}) do
    document = get_in(context, [:notification, "document"])
    document_id = external_ids[:linear_document_id]
    app_user_id = external_ids[:linear_app_user_id]

    # Fetch document content from Linear if we have the necessary IDs
    document_content =
      if document_id && app_user_id do
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
      else
        "Document content unavailable - missing document ID or app user ID"
      end

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

  defp build_issue_context(issue, action) do
    """
    Linear Issue #{action}: #{issue["title"]}

    Description:
    #{issue["description"] || "No description provided"}

    Issue URL: #{issue["url"]}
    Priority: #{issue["priority"] || "No priority set"}
    State: #{get_in(issue, ["state", "name"]) || "Unknown"}
    Team: #{get_in(issue, ["team", "name"]) || "Unknown"}
    """
  end
end
