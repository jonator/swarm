defmodule SwarmWeb.SessionController do
  use SwarmWeb, :controller

  alias Swarm.Accounts.User
  alias Swarm.Services.Github
  alias SwarmWeb.Auth.Guardian

  action_fallback SwarmWeb.FallbackController

  def github(conn, %{"code" => code}) do
    with {:ok, %User{} = user} <- Github.exchange_user_code(code),
         opts <-
           if(user.role == :admin, do: [permissions: %{default: [:admin]}], else: []),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user, %{}, opts) do
      conn
      |> put_status(:created)
      |> json(%{token: token})
    end
  end
end
