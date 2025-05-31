defmodule Swarm.Ingress.GitHubHandler do
  @moduledoc """
  Handles GitHub webhook events and determines when to spawn agents.

  This handler processes various GitHub event types:
  - Pull Request events (opened, closed, etc.)
  - Issue events (opened, assigned, commented)
  - Push events (to main/master branches)
  - Repository events (created, updated)
  """

  require Logger

  alias Swarm.Ingress.Event
  alias Swarm.Ingress.Permissions
  alias Swarm.Agents
  alias Swarm.Repositories

  @doc """
  Handles a GitHub event and determines if an agent should be spawned.

  ## Parameters
    - event: Standardized event struct from GitHub webhook

  ## Returns
    - `{:ok, agent}` - Successfully created and queued agent
    - `{:ok, :ignored}` - Event was valid but not actionable
    - `{:error, reason}` - Event processing failed
  """
  def handle(%Event{source: :github} = event) do
    Logger.info("Processing GitHub event: #{event.type}")

    with {:ok, user} <- Permissions.validate_user_access(event),
         {:ok, repository} <- find_or_create_repository(user, event),
         {:ok, agent_attrs} <- build_agent_attributes(event, user, repository) do
      case should_spawn_agent?(event) do
        true -> spawn_agent(agent_attrs)
        false -> {:ok, :ignored}
      end
    else
      {:error, reason} = error ->
        Logger.warning("GitHub event processing failed: #{reason}")
        error
    end
  end

  def handle(%Event{source: other_source}) do
    {:error, "GitHubHandler received non-GitHub event: #{other_source}"}
  end

  @doc """
  Determines if an agent should be spawned for this GitHub event.
  """
  def should_spawn_agent?(%Event{type: "issue", context: context}) do
    action = context[:action]
    issue = get_in(context, [:data, "issue"])

    # Spawn agent if:
    # 1. Issue was opened and contains implementation details
    # 2. Issue was assigned to @swarm
    # 3. Issue comment mentions @swarm
    cond do
      action == "opened" && has_implementation_plan?(issue) -> true
      action == "assigned" && assigned_to_swarm?(issue) -> true
      action == "created" && mentions_swarm?(get_in(context, [:data, "comment"])) -> true
      true -> false
    end
  end

  def should_spawn_agent?(%Event{type: "pull_request", context: context}) do
    action = context[:action]

    # Spawn agent for:
    # 2. PR ready for review after draft
    cond do
      # action == "opened" -> true
      action == "ready_for_review" -> true
      true -> false
    end
  end

  def should_spawn_agent?(%Event{type: "push"}) do
    # TODO: Implement push event handling
    false
  end

  def should_spawn_agent?(%Event{type: "repository"}) do
    # Don't spawn agents for repository events by default
    false
  end

  def should_spawn_agent?(_event) do
    false
  end

  @doc """
  Finds existing repository or creates a new one from GitHub event data.
  """
  def find_or_create_repository(user, %Event{repository_external_id: repo_id} = event)
      when not is_nil(repo_id) do
    case Repositories.get_user_repository(user, repo_id) do
      nil -> create_repository_from_event(user, event)
      repository -> {:ok, repository}
    end
  end

  def find_or_create_repository(_user, _event) do
    {:error, "No repository ID found in GitHub event"}
  end

  defp create_repository_from_event(user, %Event{context: context}) do
    repo_data = context[:repository]

    repo_attrs = %{
      external_id: "github:#{repo_data["id"]}",
      name: repo_data["name"],
      owner: repo_data["owner"]["login"]
    }

    case Repositories.create_repository(user, repo_attrs) do
      {:ok, repository} ->
        Logger.info("Created repository from GitHub event: #{repository.name}")
        {:ok, repository}

      {:error, changeset} ->
        Logger.error("Failed to create repository from GitHub event: #{inspect(changeset)}")
        {:error, "Failed to create repository"}
    end
  end

  @doc """
  Builds agent attributes from the GitHub event data.
  """
  def build_agent_attributes(%Event{} = event, user, repository) do
    base_attrs = %{
      user_id: user.id,
      repository_id: repository.id,
      source: :github,
      status: :pending
    }

    type_specific_attrs =
      case event.type do
        "issue" -> build_issue_agent_attrs(event)
        "pull_request" -> build_pr_agent_attrs(event)
        "push" -> build_push_agent_attrs(event)
        _ -> build_default_agent_attrs(event)
      end

    external_ids = Map.take(event.external_ids, [:github_issue_id, :github_pull_request_id])

    attrs = Map.merge(base_attrs, type_specific_attrs)
    attrs = Map.merge(attrs, external_ids)

    {:ok, attrs}
  end

  defp build_issue_agent_attrs(%Event{context: context}) do
    issue = get_in(context, [:data, "issue"])
    action = context[:action]

    {agent_type, agent_name} =
      if has_implementation_plan?(issue) do
        {:coder, "GitHub Issue Implementation: #{issue["title"]}"}
      else
        {:researcher, "GitHub Issue Research: #{issue["title"]}"}
      end

    context_text = build_issue_context(issue, action)

    %{
      type: agent_type,
      name: agent_name,
      context: context_text
    }
  end

  defp build_pr_agent_attrs(%Event{context: context}) do
    pr = get_in(context, [:data, "pull_request"])

    %{
      type: :code_reviewer,
      name: "GitHub PR Review: #{pr["title"]}",
      context:
        "Review pull request: #{pr["title"]}\n\nDescription: #{pr["body"] || "No description provided"}"
    }
  end

  defp build_push_agent_attrs(%Event{context: context}) do
    commits = get_in(context, [:data, "commits"]) || []
    commit_messages = Enum.map(commits, & &1["message"]) |> Enum.join("\n")

    %{
      type: :coder,
      name: "GitHub Push Analysis",
      context: "Analyze recent commits and suggest improvements:\n\n#{commit_messages}"
    }
  end

  defp build_default_agent_attrs(_event) do
    %{
      type: :researcher,
      name: "GitHub Event Analysis",
      context: "Analyze GitHub event and determine next steps"
    }
  end

  defp spawn_agent(agent_attrs) do
    case Agents.create_agent(agent_attrs) do
      {:ok, agent} ->
        Logger.info("Created agent #{agent.id} for GitHub event")

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
    body = issue["body"] || ""
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
      "database"
    ]

    text = String.downcase("#{title} #{body}")
    Enum.any?(implementation_keywords, &String.contains?(text, &1))
  end

  defp assigned_to_swarm?(issue) do
    assignees = issue["assignees"] || []

    Enum.any?(assignees, fn assignee ->
      assignee["login"] == "swarm" || String.contains?(assignee["login"] || "", "swarm")
    end)
  end

  defp mentions_swarm?(comment) when is_nil(comment), do: false

  defp mentions_swarm?(comment) do
    body = comment["body"] || ""
    String.contains?(String.downcase(body), "@swarm")
  end

  defp build_issue_context(issue, action) do
    """
    GitHub Issue #{action}: #{issue["title"]}

    Description:
    #{issue["body"] || "No description provided"}

    Issue URL: #{issue["html_url"]}
    Created by: #{get_in(issue, ["user", "login"])}
    """
  end
end
