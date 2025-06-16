defmodule Swarm.Services.Linear do
  @moduledoc """
  This module implements a Linear service for interacting with the Linear API as needed by Swarm.
  """
  use TypedStruct

  alias Swarm.Accounts
  alias Swarm.Accounts.User
  alias Swarm.Accounts.Token

  typedstruct enforce: true do
    field :access_token, %Token{type: :access}, enforce: true
  end

  @doc """
  Creates a new Linear service instance for the given user or app user id.
  """
  def new(%User{} = user) do
    case access_token(user) do
      {:ok, %Token{token: _access_token} = token} ->
        {:ok, %__MODULE__{access_token: token}}

      {:unauthorized, reason} ->
        {:unauthorized, "Unauthorized with Linear: #{reason}"}
    end
  end

  def new(app_user_id) do
    case access_token(app_user_id) do
      {:ok, %Token{token: _access_token} = token} ->
        {:ok, %__MODULE__{access_token: token}}

      {:unauthorized, reason} ->
        {:unauthorized, "Unauthorized with Linear: #{reason}"}
    end
  end

  @doc """
  Exchanges a Linear OAuth code for an access token for the given user.
  The user must be provided ahead of time (from a prior GitHub authentication).
  """
  def exchange_user_code(%User{} = user, code) do
    case linear_login(
           user,
           code: code
         ) do
      {:ok, user, _fresh_access_token} ->
        {:ok, user}

      {:error, error} ->
        {:error, "Failed to exchange code for token: #{inspect(error)}"}
    end
  end

  def organization(%User{} = user) do
    with {:ok, linear} <- new(user) do
      organization(linear)
    end
  end

  def organization(%__MODULE__{access_token: %Token{token: access_token}}) do
    query(access_token, """
      organization {
        id
        name
        teams {
          nodes {
            id
            name
          }
        }
      }
    """)
  end

  def document(%__MODULE__{access_token: %Token{token: access_token}}, document_id) do
    query(access_token, """
      document(id: "#{document_id}") {
        id
        title
        url
        content
      }
    """)
  end

  def document(app_user_id, document_id) do
    with {:ok, linear} <- new(app_user_id) do
      document(linear, document_id)
    end
  end

  def project(%__MODULE__{access_token: %Token{token: access_token}}, project_id) do
    query(access_token, """
      project(id: "#{project_id}") {
        id
        name
        teams {
          nodes {
            id
          }
        }
      }
    """)
  end

  def project(app_user_id, project_id) do
    with {:ok, linear} <- new(app_user_id) do
      project(linear, project_id)
    end
  end

  def issue(%__MODULE__{access_token: %Token{token: access_token}}, issue_id) do
    query(access_token, """
      issue(id: "#{issue_id}") {
        id
        title
        branchName
        documentContent {
          content
        }
      }
    """)
  end

  def issue(app_user_id, issue_id) do
    with {:ok, linear} <- new(app_user_id) do
      issue(linear, issue_id)
    end
  end

  def issue_comment_threads(%__MODULE__{access_token: %Token{token: access_token}}, issue_id) do
    query(access_token, """
      issue(id: "#{issue_id}") {
        id
        comments(filter: { parent: { null: true } }) {
          nodes {
            id
            body
            user {
              displayName
            }
            createdAt
            children {
              nodes {
                id
                body
                user {
                  displayName
                }
                createdAt
              }
            }
          }
        }
      }
    """)
  end

  def issue_comment_threads(app_user_id, issue_id) do
    with {:ok, linear} <- new(app_user_id) do
      issue_comment_threads(linear, issue_id)
    end
  end

  def issue_reaction(%__MODULE__{access_token: %Token{token: access_token}}, issue_id, emoji) do
    mutation(access_token, """
      reactionCreate(input: {issueId: "#{issue_id}", emoji: "#{emoji}"}) {
        reaction {
          createdAt
        }
      }
    """)
  end

  def issue_reaction(app_user_id, issue_id, emoji) do
    with {:ok, linear} <- new(app_user_id) do
      issue_reaction(linear, issue_id, emoji)
    end
  end

  def comment_reaction(
        %__MODULE__{access_token: %Token{token: access_token}},
        comment_id,
        emoji
      ) do
    mutation(access_token, """
      reactionCreate(input: {commentId: "#{comment_id}", emoji: "#{emoji}"}) {
        reaction {
          createdAt
        }
      }
    """)
  end

  def comment_reaction(app_user_id, comment_id, emoji) do
    with {:ok, linear} <- new(app_user_id) do
      comment_reaction(linear, comment_id, emoji)
    end
  end

  def has_access?(%User{} = user) do
    case access_token(user) do
      {:ok, %Token{token: _access_token}} ->
        {:ok, true}

      {:unauthorized, _reason} ->
        {:ok, false}
    end
  end

  defp query(access_token, query) do
    post(access_token, query, "query")
  end

  defp mutation(access_token, mutation) do
    post(access_token, mutation, "mutation")
  end

  defp post(access_token, term, type) do
    with {:ok, %Req.Response{status: 200, body: %{"data" => data}}} <-
           Req.new(base_url: "https://api.linear.app/graphql")
           |> Req.Request.put_header("Authorization", "Bearer #{access_token}")
           |> AbsintheClient.attach()
           |> Req.post(graphql: "#{type} { #{term} }") do
      {:ok, data}
    end
  end

  defp access_token(%User{} = user) do
    case Accounts.get_token(user, :access, :linear) do
      nil ->
        {:unauthorized,
         "No access token found for user, #{user.username} likely not authenticated with Linear."}

      %Token{} = token ->
        if Token.expired?(token) do
          {:unauthorized, "Linear access token expired for user #{user.username}"}
        else
          {:ok, token}
        end
    end
  end

  defp access_token(app_user_id) do
    case Accounts.get_token_by_linear_workspace_external_id(app_user_id) do
      nil ->
        {:unauthorized, "No access token found for app user #{app_user_id}"}

      %Token{} = token ->
        {:ok, token}
    end
  end

  defp linear_login(%User{} = user, params) do
    form =
      [
        client_id: Application.get_env(:swarm, :linear_client_id),
        client_secret: Application.get_env(:swarm, :linear_client_secret),
        grant_type: "authorization_code",
        redirect_uri: Application.get_env(:swarm, :linear_redirect_uri)
      ] ++ params

    with {:ok, %Req.Response{status: 200, body: body}} <-
           Req.post("https://api.linear.app/oauth/token",
             form: form,
             headers: [{"Content-Type", "application/x-www-form-urlencoded"}]
           ),
         %{
           "access_token" => access_token,
           "expires_in" => expires_in,
           "scope" => _scope
         } <- body,
         {:ok, %{"viewer" => viewer}} <-
           query(access_token, """
            viewer {
              id
            }
           """),
         {:ok, fresh_access_token} <-
           Accounts.save_token(user, %{
             token: access_token,
             expires_in: expires_in,
             context: :linear,
             linear_workspace_external_id: viewer["id"],
             type: :access
           }) do
      {:ok, user, fresh_access_token}
    else
      {:ok, %Req.Response{status: 401}} ->
        {:unauthorized, "Unauthorized with Linear"}

      {:ok, %Req.Response{status: 400, body: body}} ->
        {:error, "Bad request to Linear: #{inspect(body)}"}

      {:error, error} ->
        {:error, "Failed to login to Linear: #{inspect(error)}"}

      _ ->
        {:error, "Failed to login to Linear: unknown error"}
    end
  end
end
