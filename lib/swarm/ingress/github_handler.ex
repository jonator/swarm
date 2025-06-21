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
  alias Swarm.Repositories.Repository
  alias Swarm.Services.GitHub

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
           {:ok, repository, organization} <- find_repository_and_organization(user, event),
           {:ok, agent_attrs} <- build_agent_attributes(event, user, repository, organization) do
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
    action in ["opened", "edited"] && mentions_swarm?(get_in(context, [:issue]))
  end

  def relevant_event?(%Event{type: "issue_comment", context: context}) do
    action = context[:action]
    action in ["created", "edited"] && mentions_swarm?(get_in(context, [:comment]))
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
  Finds an existing repository from GitHub event data.
  """
  def find_repository_and_organization(user, %Event{repository_external_id: repo_id}) do
    case Repositories.get_user_repository(user, repo_id) do
      nil ->
        {:error, "Repository not found in your account"}

      %Repository{organization: nil} ->
        {:error, "Repository does not have an organization"}

      repository ->
        {:ok, repository, repository.organization}
    end
  end

  def find_repository_and_organization(_user, %Event{}) do
    {:error, "No repository ID found in GitHub event"}
  end

  @doc """
  Builds agent attributes from the GitHub event data.
  """
  def build_agent_attributes(
        %Event{external_ids: external_ids} = event,
        user,
        repository,
        organization
      ) do
    base_attrs = %{
      user_id: user.id,
      repository: repository,
      source: :github
    }

    {:ok, github_service} = GitHub.new(organization)

    type_specific_attrs =
      case event.type do
        "issue" ->
          build_issue_agent_attrs(event, organization, repository, github_service)

        "issue_comment" ->
          build_issue_agent_attrs(event, organization, repository, github_service)

        "pull_request" ->
          build_pr_agent_attrs(event)

        "push" ->
          build_push_agent_attrs(event)

        _ ->
          build_default_agent_attrs(event)
      end

    attrs = Map.merge(base_attrs, type_specific_attrs)
    attrs = Map.put(attrs, :external_ids, external_ids)

    {:ok, attrs}
  end

  defp build_issue_agent_attrs(%Event{context: context}, organization, repository, github_service) do
    issue = get_in(context, [:issue])
    action = context[:action]
    issue_body = get_in(issue, ["body"])

    results =
      if Mix.env() == :test do
        # In test environment, fetch serially to avoid complexity
        description_res =
          if is_nil(issue_body) or issue_body == "" do
            GitHub.issue_body(
              github_service,
              organization.name,
              repository.name,
              issue["number"]
            )
          else
            {:ok, issue_body}
          end

        comments_res =
          GitHub.issue_comments(
            github_service,
            organization.name,
            repository.name,
            issue["number"]
          )

        [description_res, comments_res]
      else
        # In other environments, fetch concurrently
        body_task =
          if is_nil(issue_body) or issue_body == "" do
            Task.async(fn ->
              GitHub.issue_body(
                github_service,
                organization.name,
                repository.name,
                issue["number"]
              )
            end)
          else
            Task.async(fn -> {:ok, issue_body} end)
          end

        comments_task =
          Task.async(fn ->
            GitHub.issue_comments(
              github_service,
              organization.name,
              repository.name,
              issue["number"]
            )
          end)

        tasks = [body_task, comments_task]

        Task.await_many(tasks, 15_000)
      end

    description =
      case Enum.at(results, 0) do
        {:ok, desc} ->
          desc

        error ->
          Logger.warning(
            "Failed to retrieve issue description for issue ##{issue["number"]}: #{inspect(error)}"
          )

          ""
      end

    comments =
      case Enum.at(results, 1) do
        {:ok, comms} ->
          comms

        error ->
          Logger.warning(
            "Failed to retrieve comments for issue ##{issue["number"]}: #{inspect(error)}"
          )

          []
      end

    comments_section =
      if Enum.any?(comments) do
        comments_text =
          Enum.map_join(comments, "\n", fn comment ->
            "- @#{get_in(comment, ["user", "login"])}: #{comment["body"]}"
          end)

        """

        Comments:
        #{comments_text}
        """
      else
        ""
      end

    context_text =
      """
      GitHub Issue #{action}: #{issue["title"]}

      Description:
      #{description}#{comments_section}

      Issue URL: #{issue["html_url"]}
      Created by: #{get_in(issue, ["user", "login"])}
      """

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

  defp mentions_swarm?(comment) when is_nil(comment), do: false

  defp mentions_swarm?(comment) do
    body = comment["body"] || ""
    github_app_username = Application.fetch_env!(:swarm, :github_app_username)
    String.contains?(String.downcase(body), "@#{github_app_username}")
  end
end
