defmodule Swarm.Services.Github do
  use TypedStruct

  alias Swarm.Accounts
  alias Swarm.Accounts.User
  alias Swarm.Accounts.Token

  typedstruct enforce: true do
    field :client, Tentacat.Client.t(), enforce: true
    field :access_token, %Token{type: :access}, enforce: true
  end

  @doc """
  Creates a new GitHub service instance for the given user.
  """
  def new(%User{} = user) do
    with {:ok, %Token{token: access_token} = token} <- access_token(user),
         client <-
           Tentacat.Client.new(%{
             access_token: access_token
           }) do
      {:ok, %__MODULE__{client: client, access_token: token}}
    else
      {:error, reason} -> {:error, "Failed to create GitHub client: #{reason}"}
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

  defp access_token(%User{} = user) do
    case Accounts.get_token(user, :access, :github) do
      # could have been cleaned up due to expiration
      nil ->
        refresh_token(user)

      %Token{} = token ->
        if Token.is_expired(token) do
          refresh_token(user)
        else
          {:ok, token}
        end
    end
  end

  defp refresh_token(%User{} = user) do
    case Accounts.get_token(user, :refresh, :github) do
      nil ->
        {:error,
         "No tokens found for user, #{user.username} likely not authenticated with GitHub."}

      %Token{token: refresh_token} ->
        case github_login(
               user,
               grant_type: "refresh_token",
               refresh_token: refresh_token
             ) do
          {:ok, _user, fresh_access_token, _fresh_refresh_token} ->
            {:ok, fresh_access_token}

          {:error, error} ->
            {:error, "Failed to exchange refresh token: #{inspect(error)}"}
        end
    end
  end

  defp github_login(user_or_nil, params) do
    form =
      [
        client_id: Application.get_env(:swarm, :github_client_id),
        client_secret: Application.get_env(:swarm, :github_client_secret)
      ] ++ params

    with {:ok, resp} <- Req.post("https://github.com/login/oauth/access_token", form: form),
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
      {:error, error} -> {:error, "Failed to login to github: #{inspect(error)}"}
      _ -> {:error, "Failed to login to github: unknown error"}
    end
  end

  defp user_from_github_user(access_token) do
    with client <-
           Tentacat.Client.new(%{
             access_token: access_token
           }),
         {200, github_user, _} <- Tentacat.Users.me(client),
         {200, [%{"email" => email, "verified" => true} | _], _} =
           Tentacat.Users.Emails.list(client),
         {:ok, user} <- Accounts.get_or_create_user(email, github_user["login"]) do
      {:ok, user}
    else
      {:error, error} -> {:error, "Failed to fetch user from github: #{inspect(error)}"}
      _ -> {:error, "Failed to fetch user from github: unknown error"}
    end
  end
end
