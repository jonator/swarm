defmodule Swarm.Services.Github do
  @doc """
  Exchanges a GitHub OAuth code for an access token and uses it to fetch the user's information and emails.

  Tokens are returned in the following format:
  `
  %{
    "access_token" => "ghu_...",
    "expires_in" => "28800",
    "refresh_token" => "ghr_...",
    "refresh_token_expires_in" => "15897600",
    "scope" => "",
    "token_type" => "bearer"
  }
  `
  """
  def exchange_user_code(code) do
    params = [
      client_id: Application.get_env(:swarm, :github_client_id),
      client_secret: Application.get_env(:swarm, :github_client_secret),
      code: code
    ]

    with {:ok, resp} <- Req.post("https://github.com/login/oauth/access_token", form: params),
         %{
           "access_token" => access_token
         } = tokens <-
           URI.decode_query(resp.body),
         client <-
           Tentacat.Client.new(%{
             access_token: access_token
           }),
         {200, user, _} <- Tentacat.Users.me(client),
         {200, [%{"email" => email, "verified" => true} | _], _} =
           Tentacat.Users.Emails.list(client) do
      {:ok, user, email, tokens}
    else
      {:error, error} -> {:error, "Failed to exchange GitHub auth code: #{inspect(error)}"}
    end
  end
end
