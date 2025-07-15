defmodule Swarm.Ingress.Permissions do
  @moduledoc """
  Handles user permission validation for event processing.

  This module validates that users have the necessary permissions to:
  - Access repositories mentioned in events
  - Spawn agents in their name
  """

  require Logger

  alias Swarm.Accounts
  alias Swarm.Accounts.{User, Identity}
  alias Swarm.Repositories
  alias Swarm.Repositories.Repository
  alias Swarm.Ingress.Event
  alias Swarm.Services.Linear

  @doc """
  Validates that a user has access to process the given event.

  ## Parameters
    - event: The standardized event struct

  ## Returns
    - `{:ok, user, repository, organization}` - User has access and user, repository, and organization records returned
    - `{:error, reason}` - User doesn't have access or validation failed
  """
  def validate_user_access(%Event{} = event) do
    with {:ok, user} <- find_user(event),
         {:ok, repository, organization} <- validate_repository_access(user, event) do
      {:ok, user, repository, organization}
    end
  end

  @doc """
  Finds the user associated with an event.

  TODO: when organization support is added, we may want to check authorization
  as an app installation instead of a user.

  For webhook events, this may involve looking up users by external identifiers.
  For manual events, the user should be provided in the event context.
  """
  def find_user(%Event{user_id: user_id}) when not is_nil(user_id) do
    case Accounts.get_user(user_id) do
      nil -> {:unauthorized, "User not found: #{user_id}"}
      %User{} = user -> {:ok, user}
    end
  end

  def find_user(%Event{source: :manual, user_id: user_id}) when not is_nil(user_id) do
    case Accounts.get_user(user_id) do
      nil -> {:unauthorized, "User not found: #{user_id}"}
      %User{} = user -> {:ok, user}
    end
  end

  def find_user(%Event{source: :github, external_ids: external_ids}) do
    sender_login = Map.get(external_ids, "github_sender_login")

    case sender_login do
      nil -> {:unauthorized, "No sender found in GitHub event"}
      username -> find_user_by_github_username(username)
    end
  end

  def find_user(%Event{source: :linear, external_ids: external_ids}) do
    actor_email = Map.get(external_ids, "linear_actor_email")
    actor_id = Map.get(external_ids, "linear_actor_id")

    case actor_email do
      nil ->
        case Accounts.get_identity(:linear, actor_id) do
          nil ->
            {:unauthorized, "No Linear actor email in event, identity not found: #{actor_id}"}

          %Identity{} = identity ->
            user = Swarm.Repo.preload(identity, :user).user

            {:ok, user}
        end

      email ->
        case Accounts.get_user_by_email(email) do
          nil ->
            case Accounts.get_identity(:linear, actor_id) do
              nil ->
                {:unauthorized, "No Linear user found with email: #{email}, or ID: #{actor_id}"}

              %Identity{} = identity ->
                user = Swarm.Repo.preload(identity, :user).user

                {:ok, user}
            end

          %User{} = user ->
            {:ok, user}
        end
    end
  end

  def find_user(%Event{source: :slack, context: context}) do
    user_id = get_in(context, [:event, "user"])

    case user_id do
      nil -> {:unauthorized, "No user ID found in Slack event"}
      slack_user_id -> find_user_by_slack_id(slack_user_id)
    end
  end

  def find_user(_event) do
    {:unauthorized, "Unable to identify user from event"}
  end

  @doc """
  Validates that a user has access to the repository mentioned in the event.
  """

  def validate_repository_access(
        %User{} = user,
        %Event{source: :linear, type: type, external_ids: external_ids} = _event
      ) do
    case external_ids["linear_team_id"] do
      nil ->
        if type == "documentMention" && external_ids["linear_project_id"] do
          find_repository_by_project_id(
            user,
            external_ids["linear_app_user_id"],
            external_ids["linear_project_id"]
          )
        else
          {:unauthorized, "No team information found in Linear event"}
        end

      team_id ->
        find_repository_by_team_id(user, team_id)
    end
  end

  def validate_repository_access(
        %User{} = user,
        %Event{source: :github, repository_external_id: repo_id} = _event
      )
      when not is_nil(repo_id) do
    case Repositories.get_user_repository(user, repo_id) do
      nil ->
        {:unauthorized, "User does not have access to repository: #{repo_id}"}

      %Repository{organization: nil} ->
        {:unauthorized, "Repository does not have an organization"}

      repository ->
        repository = Swarm.Repo.preload(repository, :organization)
        {:ok, repository, repository.organization}
    end
  end

  def validate_repository_access(%User{} = user, %Event{repository_external_id: repo_id} = _event)
      when not is_nil(repo_id) do
    case Repositories.get_user_repository(user, repo_id) do
      nil ->
        {:unauthorized, "User does not have access to repository: #{repo_id}"}

      repository ->
        repository = Swarm.Repo.preload(repository, :organization)
        {:ok, repository, repository.organization}
    end
  end

  def validate_repository_access(%User{} = _user, %Event{repository_external_id: nil} = _event) do
    # No repository specified, access granted
    {:ok, nil, nil}
  end

  # Helper functions for finding users by external identifiers

  defp find_user_by_github_username(username) do
    # For now, we assume GitHub username matches our internal username
    # This could be enhanced to use a mapping table if needed
    case Accounts.get_user_by_username(username) do
      nil -> {:unauthorized, "No user found with GitHub username: #{username}"}
      %User{} = user -> {:ok, user}
    end
  end

  defp find_user_by_slack_id(_slack_user_id) do
    # TODO: Implement Slack user ID to internal user mapping
    {:unauthorized, "Slack user mapping not yet implemented"}
  end

  defp find_repository_by_team_id(user, team_id) do
    # Look for repositories that have this Linear team ID in their external IDs
    case Repositories.list_repositories(user) do
      [] ->
        {:unauthorized, "No repositories found for user"}

      repositories ->
        matching_repo =
          Enum.find(repositories, fn repo ->
            team_id in (repo.linear_team_external_ids || [])
          end)

        case matching_repo do
          nil ->
            {:unauthorized, "No repository found with Linear team ID: #{team_id}"}

          repository ->
            repository = Swarm.Repo.preload(repository, :organization)

            if repository.organization do
              {:ok, repository, repository.organization}
            else
              {:unauthorized, "Repository #{repository.id} does not have an organization"}
            end
        end
    end
  end

  defp find_repository_by_project_id(user, workspace_id, project_id) do
    case Linear.project(workspace_id, project_id) do
      {:ok, %{"project" => %{"teams" => %{"nodes" => teams}}}} ->
        case teams do
          [] ->
            {:unauthorized,
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
        {:unauthorized, "No repository found with Linear project ID: #{project_id}"}
    end
  end
end
