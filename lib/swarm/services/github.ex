defmodule Swarm.Services.GitHub do
  @moduledoc """
  This module implements a GitHub service for interacting with the GitHub API as needed by Swarm.
  """
  use TypedStruct

  alias Swarm.Accounts
  alias Swarm.Accounts.User
  alias Swarm.Accounts.Token

  typedstruct enforce: true do
    field :client, Tentacat.Client.t(), enforce: true
    field :installation_client, Tentacat.Client.t()
    field :access_token, %Token{type: :access}, enforce: true
  end

  @doc """
  Creates a new GitHub service instance for the given user with user access token.
  """
  def new(%User{} = user) do
    with {:ok, %Token{token: access_token} = token} <- access_token(user),
         client <-
           Tentacat.Client.new(%{
             access_token: access_token
           }),
          app_jwt = SwarmWeb.Auth.GitHubToken.create(),
          installation_client <- Tentacat.Client.new(%{
            jwt: app_jwt
          }) do
      {:ok, %__MODULE__{client: client, installation_client: installation_client, access_token: token}}
    else
      {:error, reason} -> {:error, "Failed to create GitHub client: #{reason}"}
      {:unauthorized, reason} -> {:unauthorized, "Unauthorized with GitHub: #{reason}"}
      _ -> {:error, "Failed to create GitHub client"}
    end
  end

  @doc """
  Exchanges a GitHub OAuth code for an access token and uses it to
  return the associated user.
  """
  def exchange_user_code(code) do
    case github_login(
           nil,
           code: code
         ) do
      {:ok, user, _fresh_access_token, _fresh_refresh_token} ->
        {:ok, user}

      {:error, error} ->
        {:error, "Failed to exchange refresh token: #{inspect(error)}"}
    end
  end

  def installations(%User{} = user) do
    with {:ok, github} <- new(user) do
      installations(github)
    end
  end

  def installations(%__MODULE__{client: client}) do
    # https://docs.github.com/en/rest/apps/installations?apiVersion=2022-11-28#list-app-installations-accessible-to-the-user-access-token
    with {200, installations, _} <- Tentacat.App.Installations.list_for_user(client) do
      {:ok, installations}
    end
  end

  def installation_repositories(user_or_client, target_type_or_id \\ "User")

  def installation_repositories(%User{} = user, target_type) do
    with {:ok, %__MODULE__{} = client} <- new(user),
         {:ok, %{"installations" => installations}} <- installations(client),
         %{"id" => installation_id} <- Enum.find(installations, {:error, "Installation not found for user #{user.id} of target_type #{target_type}"}, &(&1["target_type"] == target_type)) do
      installation_repositories(client, installation_id)
    end
  end

  def installation_repositories(%__MODULE__{client: client}, installation_id) do
    # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-the-authenticated-user
    with {200, repositories, _} <- Tentacat.App.Installations.list_repositories_for_user(client, installation_id) do
      {:ok, repositories}
    end
  end

  def repository_trees(user_or_client, owner, repo, branch \\ "main")

  def repository_trees(%User{} = user, owner, repo, branch) do
    with {:ok, %__MODULE__{} = client} <- new(user) do
      repository_trees(client, owner, repo, branch)
    end
  end

  def repository_trees(%__MODULE__{client: client}, owner, repo, branch) do
    # https://docs.github.com/en/rest/git/trees?apiVersion=2022-11-28#get-a-tree
    with {200, tree, _} <- Tentacat.Trees.find_recursive(owner, repo, branch, client) do
      {:ok, tree}
    end
  end

  def repository_file_content(%User{} = user, owner, repo, file_path) do
    with {:ok, %__MODULE__{} = client} <- new(user) do
      repository_file_content(client, owner, repo, file_path)
    end
  end

  def repository_file_content(%__MODULE__{client: client}, owner, repo, file_path) do
    case Tentacat.Repositories.Contents.content(client, owner, repo, file_path) do
        {200, %{"content" => content, "encoding" => "base64"}, _} ->
          case Base.decode64(content, ignore: :whitespace) do
            {:ok, decoded_content} ->
              {:ok, decoded_content}
            error ->
              error
          end

        {200, %{"content" => content}, _} ->
          {:ok, content}

        error ->
          error
      end
  end

  defp access_token(%User{} = user) do
    case Accounts.get_token(user, :access, :github) do
      # could have been cleaned up due to expiration
      nil ->
        refresh_token(user)

      %Token{} = token ->
        if Token.expired?(token) do
          refresh_token(user)
        else
          {:ok, token}
        end
    end
  end

  # Refreshes the GitHub access token for a user using the cached refresh token.
  defp refresh_token(%User{} = user) do
    case Accounts.get_token(user, :refresh, :github) do
      nil ->
        {:unauthorized,
         "No tokens found for user, #{user.username} likely not authenticated with GitHub."}

      %Token{token: refresh_token} ->
        with {:ok, _user, fresh_access_token, _fresh_refresh_token} <- github_login(
               user,
               grant_type: "refresh_token",
               refresh_token: refresh_token
             ) do
          {:ok, fresh_access_token}
        end
    end
  end

  defp github_login(user_or_nil, params) do
    form =
      [
        client_id: Application.get_env(:swarm, :github_client_id),
        client_secret: Application.get_env(:swarm, :github_client_secret)
      ] ++ params

    with {:ok, %Req.Response{status: 200} = resp} <- Req.post("https://github.com/login/oauth/access_token", form: form),
         %{
           "access_token" => access_token,
           "expires_in" => expires_in,
           "refresh_token" => refresh_token,
           "refresh_token_expires_in" => refresh_token_expires_in
         } <-
           URI.decode_query(resp.body),
         {:ok, user} <-
           if(user_or_nil == nil,
             do: user_from_github_user(access_token),
             else: {:ok, user_or_nil}
           ),
         {:ok, fresh_access_token} <-
           Accounts.save_token(user, %{
             token: access_token,
             expires_in: String.to_integer(expires_in),
             context: :github,
             type: :access
           }),
         {:ok, fresh_refresh_token} <-
           Accounts.save_token(user, %{
             token: refresh_token,
             expires_in: String.to_integer(refresh_token_expires_in),
             context: :github,
             type: :refresh
           }) do
      {:ok, user, fresh_access_token, fresh_refresh_token}
    else
      {:ok, %Req.Response{status: 401}} -> {:unauthorized, "Unauthorized with GitHub: user_or_nil-#{user_or_nil}"}
      {:error, error} -> {:error, "Failed to login to github: #{inspect(error)}"}
      _ -> {:error, "Failed to login to github: unknown error"}
    end
  end

  defp user_from_github_user(access_token) do
    with client <-
           Tentacat.Client.new(%{
             access_token: access_token
           }),
         {200, %{"login" => login, "avatar_url" => avatar_url}, _} <- Tentacat.Users.me(client),
         {200, [%{"email" => email, "verified" => true} | _], _} =
           Tentacat.Users.Emails.list(client),
         {:ok, user} <- Accounts.get_or_create_user(email, login, avatar_url) do
      {:ok, user}
    else
      {401, %{"message" => message}, _} -> {:unauthorized, "Unauthorized with GitHub: #{message}"}
      {:error, error} -> {:error, "Failed to fetch user from github: #{inspect(error)}"}
      _ -> {:error, "Failed to fetch user from github: unknown error"}
    end
  end
end
