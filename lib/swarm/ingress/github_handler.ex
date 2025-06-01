defmodule Swarm.Ingress.GitHubHandler do
  @moduledoc """
  Handles GitHub webhook events and generates agent attributes.

  This handler processes various GitHub event types:
  - Pull Request events (opened, closed, etc.)
  - Issue events (opened, assigned, commented)
  - Push events (to main/master branches)
  - Repository events (created, updated)
  """

  require Logger

  alias Swarm.Ingress.Event
  alias Swarm.Ingress.Permissions
  alias Swarm.Repositories

  @doc """
  Handles a GitHub event and generates agent attributes.

  ## Parameters
    - event: Standardized event struct from GitHub webhook

  ## Returns
    - `{:ok, agent_attrs}` - Successfully built agent attributes
    - `{:ok, :ignored}` - Event was valid but not actionable
    - `{:error, reason}` - Event processing failed
  """
  def handle(%Event{source: :github} = event) do
    Logger.info("Processing GitHub event: #{event.type}")

    # Check if event is relevant first
    if relevant_event?(event) do
      with {:ok, user} <- Permissions.validate_user_access(event),
           {:ok, repository} <- find_or_create_repository(user, event),
           {:ok, agent_attrs} <- build_agent_attributes(event, user, repository) do
        {:ok, agent_attrs}
      else
        {:error, reason} = error ->
          Logger.warning("GitHub event processing failed: #{reason}")
          error
      end
    else
      {:ok, :ignored}
    end
  end

  def handle(%Event{source: other_source}) do
    {:error, "GitHubHandler received non-GitHub event: #{other_source}"}
  end

  @doc """
  Determines if an event is relevant for processing.
  """
  def relevant_event?(%Event{type: "issue", context: context}) do
    action = context[:action]
    issue = get_in(context, [:data, "issue"])

    # Process events for:
    # 1. Issue was opened
    # 2. Issue was assigned to @swarm
    # 3. Issue comment mentions @swarm
    cond do
      action == "opened" -> true
      action == "assigned" && assigned_to_swarm?(issue) -> true
      action == "created" && mentions_swarm?(get_in(context, [:data, "comment"])) -> true
      true -> false
    end
  end

  def relevant_event?(%Event{type: "pull_request", context: context}) do
    action = context[:action]

    # Process events for:
    # PR ready for review after draft
    action == "ready_for_review"
  end

  def relevant_event?(%Event{type: "push"}) do
    # TODO: Implement push event handling
    false
  end

  def relevant_event?(%Event{type: "repository"}) do
    # Don't process repository events by default
    false
  end

  def relevant_event?(_event) do
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
      repository: repository,
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

    context_text = build_issue_context(issue, action)

    %{
      context: context_text
    }
  end

  defp build_pr_agent_attrs(%Event{context: context}) do
    pr = get_in(context, [:data, "pull_request"])

    %{
      context:
        "Review pull request: #{pr["title"]}\n\nDescription: #{pr["body"] || "No description provided"}"
    }
  end

  defp build_push_agent_attrs(%Event{context: context}) do
    commits = get_in(context, [:data, "commits"]) || []
    commit_messages = Enum.map_join(commits, "\n", & &1["message"])

    %{
      context: "Analyze recent commits and suggest improvements:\n\n#{commit_messages}"
    }
  end

  defp build_default_agent_attrs(_event) do
    %{
      context: "Analyze GitHub event and determine next steps"
    }
  end

  # Helper functions for event analysis

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
