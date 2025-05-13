defmodule SwarmWeb.SessionController do
  use SwarmWeb, :controller

  alias Swarm.Accounts
  alias Swarm.Services.Github
  alias SwarmWeb.Auth.Guardian

  action_fallback SwarmWeb.FallbackController

  def github(conn, %{"code" => code}) do
    with {:ok, github_user, tokens} <- Github.exchange_user_code(code),
         {:ok, user} <- Accounts.get_or_create_user(github_user["email"], github_user["login"]),
         opts <-
           if(user.role == :admin, do: [permissions: %{default: [:admin]}], else: []),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user, %{}, opts),
         {:ok, _} <-
           Accounts.save_token(user, %{
             token: tokens["access_token"],
             expires_in: String.to_integer(tokens["expires_in"]),
             context: :github,
             type: :access
           }),
         {:ok, _} <-
           Accounts.save_token(user, %{
             token: tokens["refresh_token"],
             expires_in: String.to_integer(tokens["refresh_token_expires_in"]),
             context: :github,
             type: :refresh
           }) do
      conn
      |> put_status(:created)
      |> json(%{token: token})
    end
  end
end
