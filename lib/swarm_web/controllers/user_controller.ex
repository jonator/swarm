defmodule SwarmWeb.UserController do
  use SwarmWeb, :controller
  use SwarmWeb.CurrentResource

  alias Swarm.Accounts
  alias Swarm.Accounts.User

  action_fallback SwarmWeb.FallbackController

  def index(conn, _params, _user) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  def create(conn, %{"user" => user_params}, _user) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> render(:show, user: user)
    end
  end

  def show(conn, %{"id" => id}, _user) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def show(conn, _params, user) do
    render(conn, :show, user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}, _user) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}, _user) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
