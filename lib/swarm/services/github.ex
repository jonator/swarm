defmodule Swarm.Services.GitHub do
  @moduledoc """
  This module implements a GitHub service for interacting with the GitHub API as needed by Swarm.
  """
  use TypedStruct

  alias Swarm.Accounts
  alias Swarm.Accounts.User
  alias Swarm.Accounts.Token
  alias Swarm.Organizations.Organization

  typedstruct enforce: true do
    field :client, Tentacat.Client.t(), enforce: true
  end

  @doc """
  Creates a new GitHub service instance using JWT authentication. Useful for authenticating as the Swarm app itself.

  See: https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/about-authentication-with-a-github-app#authentication-as-a-github-app
  """
  def new() do
    {:ok, app_jwt, _} = SwarmWeb.Auth.GitHubToken.create()
    client = Tentacat.Client.new(%{jwt: app_jwt})
    {:ok, %__MODULE__{client: client}}
  end

  @doc """
  Creates a new GitHub service instance for the given user with user access token.
  """
  def new(%User{} = user) do
    with {:ok, %Token{token: access_token}} <- access_token(user),
         client <-
           Tentacat.Client.new(%{
             access_token: access_token
           }) do
      {:ok, %__MODULE__{client: client}}
    else
      {:error, reason} -> {:error, "Failed to create GitHub client: #{reason}"}
      {:unauthorized, reason} -> {:unauthorized, "Unauthorized with GitHub: #{reason}"}
      _ -> {:error, "Failed to create GitHub client"}
    end
  end

  def new(%Organization{} = organization) do
    with {:ok, access_token} <- access_token(organization),
         client <-
           Tentacat.Client.new(%{
             access_token: access_token
           }) do
      {:ok, %__MODULE__{client: client}}
    end
  end

  @doc """
  Exchanges a GitHub OAuth code for an access token and uses it to
  return the associated user. Saves the access token and refresh token to the database.
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
    # https://docs.github.com/en/rest/apops/installations?apiVersion=2022-11-28#list-app-installations-accessible-to-the-user-access-token
    with {200, installations, _} <- Tentacat.App.Installations.list_for_user(client) do
      {:ok, installations}
    end
  end

  def installation_repositories(user_or_client, target_type_or_id \\ "User")

  def installation_repositories(%User{} = user, target_type)
      when target_type in ["User", "Organization"] do
    with {:ok, %__MODULE__{} = client} <- new(user),
         {:ok, %{"installations" => installations}} <- installations(client),
         %{"id" => installation_id} <-
           Enum.find(
             installations,
             {:error, "Installation not found for user #{user.id} of target_type #{target_type}"},
             &(&1["target_type"] == target_type)
           ) do
      installation_repositories(client, installation_id)
    end
  end

  def installation_repositories(%__MODULE__{client: client}, installation_id) do
    # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-the-authenticated-user
    with {200, repositories, _} <-
           Tentacat.App.Installations.list_repositories_for_user(client, installation_id) do
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

  def repository_info(user_or_client, owner, repo)

  def repository_info(%User{} = user, owner, repo) do
    with {:ok, %__MODULE__{} = client} <- new(user) do
      repository_info(client, owner, repo)
    end
  end

  def repository_info(%__MODULE__{client: client}, owner, repo) do
    # https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#get-a-repository
    with {200, repo_info, _} <- Tentacat.Repositories.repo_get(client, owner, repo) do
      {:ok, repo_info}
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

  @doc """
  Returns the body for the given issue.

  ## Example

  `
  {:ok, body} = GitHub.issue_body(github_service, "elixir-lang", "elixir", 2974)
  `

  ## Response

  `
  {:ok, "This is the description of the issue"}
  `

  """
  def issue_body(%__MODULE__{client: client}, owner, repo, issue_number) do
    case Tentacat.Issues.find(client, owner, repo, issue_number) do
      {200, %{"body" => body}, _} ->
        {:ok, body}

      error ->
        error
    end
  end

  @doc """
  Returns the comments for the given issue.

  ## Example

  `
  {:ok, comments} = GitHub.issue_comments(github_service, "elixir-lang", "elixir", 2974)
  `

  ## Example

  `
  {:ok, comments} = GitHub.issue_comments(github_service, "elixir-lang", "elixir", 2974)
  `

  Returns a list of comment maps with fields like in the :ok tuple:
  `
  [
    %{
      "author_association" => "OWNER",
      "body" => "Test comment",
      "created_at" => "2025-06-21T03:02:05Z",
      "html_url" => "https://github.com/jonator/swarm/issues/5#issuecomment-2993277196",
      "id" => 2993277196,
      "issue_url" => "https://api.github.com/repos/jonator/swarm/issues/5",
      "node_id" => "IC_kwDOOSfB686yackM",
      "performed_via_github_app" => nil,
      "reactions" => %{
        "+1" => 0,
        "-1" => 0,
        "confused" => 0,
        "eyes" => 0,
        "heart" => 0,
        "hooray" => 0,
        "laugh" => 0,
        "rocket" => 0,
        "total_count" => 0,
        "url" => "https://api.github.com/repos/jonator/swarm/issues/comments/2993277196/reactions"
      },
      "updated_at" => "2025-06-21T03:02:05Z",
      "url" => "https://api.github.com/repos/jonator/swarm/issues/comments/2993277196",
      "user" => %{
        "avatar_url" => "https://avatars.githubusercontent.com/u/4606373?v=4",
        "events_url" => "https://api.github.com/users/jonator/events{/privacy}",
        "followers_url" => "https://api.github.com/users/jonator/followers",
        "following_url" => "https://api.github.com/users/jonator/following{/other_user}",
        "gists_url" => "https://api.github.com/users/jonator/gists{/gist_id}",
        "gravatar_id" => "",
        "html_url" => "https://github.com/jonator",
        "id" => 4606373,
        "login" => "jonator",
        "node_id" => "MDQ6VXNlcjQ2MDYzNzM=",
        "organizations_url" => "https://api.github.com/users/jonator/orgs",
        "received_events_url" => "https://api.github.com/users/jonator/received_events",
        "repos_url" => "https://api.github.com/users/jonator/repos",
        "site_admin" => false,
        "starred_url" => "https://api.github.com/users/jonator/starred{/owner}{/repo}",
        "subscriptions_url" => "https://api.github.com/users/jonator/subscriptions",
        "type" => "User",
        "url" => "https://api.github.com/users/jonator",
        "user_view_type" => "public"
      }
    }
  ]
  `
  """
  def issue_comments(%__MODULE__{client: client}, owner, repo, issue_number) do
    case Tentacat.Issues.Comments.list(client, owner, repo, issue_number) do
      {200, comments, _} ->
        {:ok, comments}

      error ->
        error
    end
  end

  @doc """
  Creates a comment on a GitHub issue.
  """
  def create_issue_comment(%Organization{name: name} = org, repo, issue_number, body) do
    with {:ok, %__MODULE__{} = client} <- new(org) do
      create_issue_comment(client, name, repo, issue_number, body)
    end
  end

  def create_issue_comment(%__MODULE__{client: client}, owner, repo, issue_number, body) do
    comment = %{"body" => body}

    case Tentacat.Issues.Comments.create(client, owner, repo, issue_number, comment) do
      {201, comment, _} ->
        {:ok, comment}

      error ->
        error
    end
  end

  @doc """
  Creates a pull request for the given organization and repository.

  Pull Request body example:

  ```elixir
  %{
    "title" => "Amazing new feature",
    "body"  => "Please pull this in!",
    "head"  => "octocat:new-feature",
    "base"  => "master"
   }
  ```

  Alternative input (using an existing issue):

  ```elixir
  %{
    "issue" => "5",
    "head"  => "octocat:new-feature",
    "base"  => "master"
   }
  ```
  """
  def create_pull(%Organization{name: name} = org, repo, attrs) do
    with {:ok, %__MODULE__{} = client} <- new(org) do
      create_pull(client, name, repo, attrs)
    end
  end

  def create_pull(%__MODULE__{client: client}, owner, repo, attrs) do
    # https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28#create-a-pull-request
    with {201, %{"number" => number}, _} <- Tentacat.Pulls.create(client, owner, repo, attrs) do
      {:ok, number}
    end
  end

  def comment_reaction_create(%Organization{name: name} = org, repo, comment_id, body) do
    with {:ok, %__MODULE__{} = client} <- new(org) do
      comment_reaction_create(client, name, repo, comment_id, body)
    end
  end

  def comment_reaction_create(%__MODULE__{client: client}, owner, repo, comment_id, body) do
    # https://developer.github.com/v3/reactions/#create-reaction-for-an-issue-comment
    case Tentacat.Issues.Comments.Reactions.create(client, owner, repo, comment_id, body) do
      {201, reaction, _} -> {:ok, reaction}
      error -> error
    end
  end

  def issue_reaction_create(%Organization{name: name} = org, repo, issue_id, body) do
    with {:ok, %__MODULE__{} = client} <- new(org) do
      issue_reaction_create(client, name, repo, issue_id, body)
    end
  end

  def issue_reaction_create(%__MODULE__{client: client}, owner, repo, issue_id, body) do
    # https://developer.github.com/v3/reactions/#create-reaction-for-an-issue
    case Tentacat.Issues.Reactions.create(client, owner, repo, issue_id, body) do
      {201, reaction, _} -> {:ok, reaction}
      error -> error
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

  defp access_token(%Organization{github_installation_id: github_installation_id}) do
    with {:ok, jwt_gh} <- new(),
         {201, %{"token" => token}, _} <-
           Tentacat.App.Installations.token(jwt_gh.client, github_installation_id) do
      {:ok, token}
    end
  end

  defp refresh_token(%User{} = user) do
    case Accounts.get_token(user, :refresh, :github) do
      nil ->
        {:unauthorized,
         "No tokens found for user, #{user.username} likely not authenticated with GitHub."}

      %Token{token: refresh_token} ->
        with {:ok, _user, fresh_access_token, _fresh_refresh_token} <-
               github_login(
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

    with {:ok, %Req.Response{status: 200} = resp} <-
           Req.post("https://github.com/login/oauth/access_token", form: form),
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
      {:ok, %Req.Response{status: 401}} ->
        {:unauthorized, "Unauthorized with GitHub: user_or_nil-#{user_or_nil}"}

      {:error, error} ->
        {:error, "Failed to login to github: #{inspect(error)}"}

      _ ->
        {:error, "Failed to login to github: unknown error"}
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
