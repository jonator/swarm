defmodule SwarmWeb.LinearController do
  use SwarmWeb, :controller
  use SwarmWeb.Auth.CurrentResource

  alias Swarm.Accounts.User
  alias Swarm.Services.Linear

  action_fallback SwarmWeb.FallbackController

  def exchange_code(conn, %{"code" => code}, user) do
    with {:ok, %User{}} <- Linear.exchange_user_code(user, code) do
      conn
      |> put_status(:ok)
      |> json(%{has_access: true})
    end
  end

  def has_access(conn, _params, user) do
    with {:ok, has_access} <- Linear.has_access?(user) do
      conn
      |> put_status(:ok)
      |> json(%{has_access: has_access})
    end
  end
end
