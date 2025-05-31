defmodule Swarm.Ingress.Permissions do
  @moduledoc """
  Handles user permission validation for event processing.

  This module validates that users have the necessary permissions to:
  - Access repositories mentioned in events
  - Spawn agents in their name
  - Perform actions on external services
  """

  alias Swarm.Accounts
  alias Swarm.Accounts.User
  alias Swarm.Repositories
  alias Swarm.Ingress.Event

  @doc """
  Validates that a user has access to process the given event.

  ## Parameters
    - event: The standardized event struct

  ## Returns
    - `{:ok, user}` - User has access and user record returned
    - `{:error, reason}` - User doesn't have access or validation failed
  """
  def validate_user_access(%Event{} = event) do
    with {:ok, user} <- find_user(event),
         :ok <- validate_repository_access(user, event),
         :ok <- validate_service_access(user, event) do
      {:ok, user}
    end
  end

  @doc """
  Finds the user associated with an event.

  For webhook events, this may involve looking up users by external identifiers.
  For manual events, the user should be provided in the event context.
  """
  def find_user(%Event{source: :manual, user_id: user_id}) when not is_nil(user_id) do
    case Accounts.get_user(user_id) do
      nil -> {:error, "User not found: #{user_id}"}
      %User{} = user -> {:ok, user}
    end
  end

  def find_user(%Event{source: :github, context: context}) do
    sender = get_in(context, [:sender, "login"])

    case sender do
      nil -> {:error, "No sender found in GitHub event"}
      username -> find_user_by_github_username(username)
    end
  end

  def find_user(%Event{source: :linear, context: context}) do
    actor = get_in(context, [:actor, "email"])

    case actor do
      nil -> {:error, "No actor email found in Linear event"}
      email -> find_user_by_email(email)
    end
  end

  def find_user(%Event{source: :slack, context: context}) do
    user_id = get_in(context, [:event, "user"])

    case user_id do
      nil -> {:error, "No user ID found in Slack event"}
      slack_user_id -> find_user_by_slack_id(slack_user_id)
    end
  end

  def find_user(%Event{user_id: user_id}) when not is_nil(user_id) do
    case Accounts.get_user(user_id) do
      nil -> {:error, "User not found: #{user_id}"}
      %User{} = user -> {:ok, user}
    end
  end

  def find_user(_event) do
    {:error, "Unable to identify user from event"}
  end

  @doc """
  Validates that a user has access to the repository mentioned in the event.
  """
  def validate_repository_access(_user, %Event{repository_external_id: nil}) do
    # No repository specified, access granted
    :ok
  end

  def validate_repository_access(%User{} = user, %Event{repository_external_id: repo_id}) do
    case Repositories.get_user_repository(user, repo_id) do
      nil -> {:error, "User does not have access to repository: #{repo_id}"}
      _repository -> :ok
    end
  end

  @doc """
  Validates that a user has the necessary service access for the event source.
  """
  def validate_service_access(%User{} = user, %Event{source: :github}) do
    # Check if user has GitHub access token
    case Accounts.get_token(user, :access, :github) do
      nil ->
        {:error, "User does not have GitHub access"}

      token ->
        if Swarm.Accounts.Token.expired?(token) do
          {:error, "User's GitHub access token has expired"}
        else
          :ok
        end
    end
  end

  def validate_service_access(%User{} = user, %Event{source: :linear}) do
    # Check if user has Linear access token
    case Accounts.get_token(user, :access, :linear) do
      nil ->
        {:error, "User does not have Linear access"}

      token ->
        if Swarm.Accounts.Token.expired?(token) do
          {:error, "User's Linear access token has expired"}
        else
          :ok
        end
    end
  end

  def validate_service_access(%User{}, %Event{source: :slack}) do
    # TODO: Implement Slack access validation when Slack integration is added
    {:error, "Slack integration not yet implemented"}
  end

  def validate_service_access(%User{}, %Event{source: :manual}) do
    # Manual events don't require external service access
    :ok
  end

  # Helper functions for finding users by external identifiers

  defp find_user_by_github_username(username) do
    # For now, we assume GitHub username matches our internal username
    # This could be enhanced to use a mapping table if needed
    case Accounts.get_user_by_username(username) do
      nil -> {:error, "No user found with GitHub username: #{username}"}
      %User{} = user -> {:ok, user}
    end
  end

  defp find_user_by_email(email) do
    case Accounts.get_user_by_email(email) do
      nil -> {:error, "No user found with email: #{email}"}
      %User{} = user -> {:ok, user}
    end
  end

  defp find_user_by_slack_id(_slack_user_id) do
    # TODO: Implement Slack user ID to internal user mapping
    {:error, "Slack user mapping not yet implemented"}
  end
end
