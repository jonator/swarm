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
  end

  def handle(%Event{source: other_source}) do
    {:error, "LinearHandler received non-Linear event: #{other_source}"}
  end

  @doc """
  Determines if an agent should be spawned for this Linear event.
  """
  def should_spawn_agent?(%Event{type: "issue_assigned", context: context}) do
    issue = get_in(context, [:data, "issue"])
    assignee = get_in(issue, ["assignee"])

    # Check if assigned to Swarm
    is_swarm_assignee?(assignee)
  end

  def should_spawn_agent?(%Event{type: "comment_mention", context: context}) do
    comment = get_in(context, [:data, "comment"])

    # Always spawn for @swarm mentions in comments
    mentions_swarm?(comment["body"])
  end

  def should_spawn_agent?(%Event{type: "description_mention", context: context}) do
    issue = get_in(context, [:data, "issue"])

    # Always spawn for @swarm mentions in descriptions
    mentions_swarm?(issue["description"])
  end

  def should_spawn_agent?(%Event{type: "document_mention", context: context}) do
    document = get_in(context, [:data, "document"])

    # Always spawn for @swarm mentions in documents
    mentions_swarm?(document["content"])
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
    issue = get_in(context, [:data, "issue"])
    team = get_in(issue, ["team"])

    case team do
      nil ->
        # Try to find a default repository for the user
        find_default_repository(user)

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
            # If no specific mapping, use the first repository
            {:ok, List.first(repositories)}

          repository ->
            {:ok, repository}
        end
    end
  end

  defp find_default_repository(user) do
    case Repositories.list_repositories(user) do
      [] -> {:error, "No repositories found for user"}
      [repository] -> {:ok, repository}
      # Use first as default
      repositories -> {:ok, List.first(repositories)}
    end
  end

  @doc """
  Builds agent attributes from the Linear event data.
  """
  def build_agent_attributes(%Event{} = event, user, repository) do
    base_attrs = %{
      user_id: user.id,
      repository_id: repository.id,
      source: :linear,
      status: :pending
    }

    type_specific_attrs =
      case event.type do
        "issue_assigned" -> build_issue_assigned_attrs(event)
        "comment_mention" -> build_comment_mention_attrs(event)
        "description_mention" -> build_description_mention_attrs(event)
        "document_mention" -> build_document_mention_attrs(event)
        _ -> build_default_agent_attrs(event)
      end

    external_ids = Map.take(event.external_ids, [:linear_issue_id])

    attrs = Map.merge(base_attrs, type_specific_attrs)
    attrs = Map.merge(attrs, external_ids)

    {:ok, attrs}
  end

  defp build_issue_assigned_attrs(%Event{context: context}) do
    issue = get_in(context, [:data, "issue"])

    {agent_type, agent_name} =
      if has_implementation_plan?(issue) do
        {:coder, "Linear Issue Implementation: #{issue["title"]}"}
      else
        {:researcher, "Linear Issue Research: #{issue["title"]}"}
      end

    context_text = build_issue_context(issue, "assigned")

    %{
      type: agent_type,
      name: agent_name,
      context: context_text,
      source_external_id: "linear:issue:#{issue["id"]}"
    }
  end

  defp build_comment_mention_attrs(%Event{context: context}) do
    comment = get_in(context, [:data, "comment"])
    issue = get_in(context, [:data, "issue"])

    context_text = """
    Linear Comment Mention in Issue: #{issue["title"]}

    Comment: #{comment["body"]}

    Issue Description:
    #{issue["description"] || "No description provided"}

    Issue URL: #{issue["url"]}
    """

    %{
      type: :researcher,
      name: "Linear Comment Response: #{issue["title"]}",
      context: context_text,
      source_external_id: "linear:comment:#{comment["id"]}"
    }
  end

  defp build_description_mention_attrs(%Event{context: context}) do
    issue = get_in(context, [:data, "issue"])

    {agent_type, agent_name} =
      if has_implementation_plan?(issue) do
        {:coder, "Linear Issue Implementation: #{issue["title"]}"}
      else
        {:researcher, "Linear Issue Analysis: #{issue["title"]}"}
      end

    context_text = build_issue_context(issue, "mentioned in description")

    %{
      type: agent_type,
      name: agent_name,
      context: context_text,
      source_external_id: "linear:issue:#{issue["id"]}"
    }
  end

  defp build_document_mention_attrs(%Event{context: context}) do
    document = get_in(context, [:data, "document"])

    context_text = """
    Linear Document Mention: #{document["title"]}

    Content excerpt with @swarm mention:
    #{extract_mention_context(document["content"])}

    Document URL: #{document["url"]}
    """

    %{
      type: :researcher,
      name: "Linear Document Response: #{document["title"]}",
      context: context_text,
      source_external_id: "linear:document:#{document["id"]}"
    }
  end

  defp build_default_agent_attrs(_event) do
    %{
      type: :researcher,
      name: "Linear Event Analysis",
      context: "Analyze Linear event and determine next steps"
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

  defp has_implementation_plan?(issue) do
    description = issue["description"] || ""
    title = issue["title"] || ""

    # Check for implementation indicators
    implementation_keywords = [
      "implementation",
      "implement",
      "steps:",
      "todo:",
      "file:",
      "function:",
      "method:",
      "class:",
      "component:",
      "endpoint:",
      "api:",
      "database",
      "step 1",
      "step 2",
      "step by step"
    ]

    text = String.downcase("#{title} #{description}")
    Enum.any?(implementation_keywords, &String.contains?(text, &1))
  end

  defp is_swarm_assignee?(nil), do: false

  defp is_swarm_assignee?(assignee) do
    name = assignee["name"] || ""
    email = assignee["email"] || ""

    String.contains?(String.downcase(name), "swarm") ||
      String.contains?(String.downcase(email), "swarm")
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

  defp extract_mention_context(content) when is_binary(content) do
    # Find the paragraph containing @swarm and return some context
    lines = String.split(content, "\n")

    mention_line =
      Enum.find(lines, fn line ->
        String.contains?(String.downcase(line), "@swarm")
      end)

    case mention_line do
      # First 500 chars if no specific mention found
      nil ->
        String.slice(content, 0, 500)

      line ->
        # Return the mention line plus some surrounding context
        line_index = Enum.find_index(lines, &(&1 == line))
        start_index = max(0, line_index - 1)
        end_index = min(length(lines) - 1, line_index + 1)

        lines
        |> Enum.slice(start_index..end_index)
        |> Enum.join("\n")
    end
  end

  defp extract_mention_context(_content), do: "Unable to extract content"
end
