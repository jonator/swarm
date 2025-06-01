defmodule Swarm.Ingress.LinearHandler do
  @moduledoc """
  Handles Linear webhook events and determines when to spawn agents.

  This handler processes various Linear event types:
  - Issue assigned to @swarm
  - @swarm mentioned in comments
  - @swarm mentioned in issue descriptions
  - @swarm mentioned in documents
  """

  require Logger

  alias Swarm.Ingress.Event
  alias Swarm.Ingress.Permissions
  alias Swarm.Agents
  alias Swarm.Repositories

  @doc """
  Handles a Linear event and determines if an agent should be spawned.

  ## Parameters
    - event: Standardized event struct from Linear webhook

  ## Returns
    - `{:ok, agent}` - Successfully created and queued agent
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
        case should_spawn_agent?(event) do
          true -> spawn_agent(agent_attrs)
          false -> {:ok, :ignored}
        end
      else
        {:error, reason} = error ->
          Logger.warning("Linear event processing failed: #{reason}")
          error
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
  Determines if an agent should be spawned for this Linear event.
  """
  def should_spawn_agent?(%Event{type: "issueAssignedToYou", context: _context}) do
    # For the new notification format, if we receive an "issueAssignedToYou" action,
    # it means it was assigned to the app user (which should be Swarm)
    true
  end

  def should_spawn_agent?(%Event{type: "issueCommentMention", context: context}) do
    # Handle both new notification format and legacy format
    comment = get_comment_from_context(context)

    # Always spawn for @swarm mentions in comments
    mentions_swarm?(comment["body"])
  end

  def should_spawn_agent?(%Event{type: "issueMention", context: context}) do
    # Handle both new notification format and legacy format
    issue = get_issue_from_context(context)

    # Always spawn for @swarm mentions in descriptions
    mentions_swarm?(issue["description"])
  end

  def should_spawn_agent?(%Event{type: "documentMention", context: _context}) do
    # For documentMention events, the fact that we received this webhook
    # means @swarm was mentioned in the document, so always spawn
    true
  end

  def should_spawn_agent?(_event) do
    false
  end

  @doc """
  Finds the repository associated with a Linear event.

  Linear events need to be mapped to repositories, which can be done through:
  1. Linear team external IDs stored in repository records
  2. Project associations
  3. Manual configuration
  """
  def find_repository_for_linear_event(user, %Event{context: context}) do
    team = get_team_from_context(context)

    case team do
      nil ->
        {:error, "No team information found in Linear event"}

      %{"id" => team_id} ->
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

  @doc """
  Builds agent attributes from the Linear event data.
  """
  def build_agent_attributes(%Event{} = event, user, repository) do
    base_attrs = %{
      user_id: user.id,
      repository_id: repository.id,
      repository: repository,
      source: :linear,
      status: :pending,
      name: build_agent_name(event),
      type: determine_agent_type(event)
    }

    type_specific_attrs =
      case event.type do
        "issueAssignedToYou" -> build_issue_assigned_attrs(event)
        "issueCommentMention" -> build_comment_mention_attrs(event)
        "issueMention" -> build_description_mention_attrs(event)
        "documentMention" -> build_document_mention_attrs(event)
        _ -> %{}
      end

    # Extract linear_issue_id from the context
    issue = get_issue_from_context(event.context)
    linear_issue_id = issue["id"]

    external_ids = Map.take(event.external_ids, [:linear_comment_id])

    external_ids =
      if linear_issue_id,
        do: Map.put(external_ids, :linear_issue_id, linear_issue_id),
        else: external_ids

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

  defp build_document_mention_attrs(%Event{context: context}) do
    document = get_in(context, [:notification, "document"])

    context_text = """
    Linear Document Mention: #{document["title"]}

    @swarm was mentioned in this document.

    Document URL: #{document["url"] || "No URL available"}
    """

    %{
      context: context_text
    }
  end

  defp spawn_agent(agent_attrs) do
    case Agents.create_agent(agent_attrs) do
      {:ok, agent} ->
        Logger.info("Created agent #{agent.id} for Linear event")

        # TODO: Queue the agent job with Oban
        # This would integrate with the existing worker system

        {:ok, agent}

      {:error, changeset} ->
        Logger.error("Failed to create agent: #{inspect(changeset)}")
        {:error, "Failed to create agent"}
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

  defp get_team_from_context(context) do
    issue = get_issue_from_context(context)
    get_in(issue, ["team"])
  end

  defp mentions_swarm?(nil), do: false

  defp mentions_swarm?(text) do
    String.contains?(String.downcase(text), "@swarm")
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

  defp build_agent_name(%Event{type: type, context: context}) do
    issue = get_issue_from_context(context)
    title = issue["title"] || "Linear Event"

    case type do
      "issueAssignedToYou" ->
        if has_implementation_plan?(context) do
          "Linear Issue Implementation: #{title}"
        else
          "Linear Issue Research: #{title}"
        end

      "issueCommentMention" ->
        "Linear Comment Response: #{title}"

      "issueMention" ->
        "Linear Issue Analysis: #{title}"

      "documentMention" ->
        document = get_in(context, [:notification, "document"])
        "Linear Document Response: #{document["title"] || "Unknown document"}"

      _ ->
        "Linear: #{title}"
    end
  end

  defp determine_agent_type(%Event{context: context}) do
    if has_implementation_plan?(context) do
      :coder
    else
      :researcher
    end
  end

  defp has_implementation_plan?(context) do
    issue = get_issue_from_context(context)
    description = issue["description"] || ""

    # Check if the description contains implementation plan keywords
    String.contains?(String.downcase(description), ["implementation plan", "step 1", "step 2"])
  end
end
