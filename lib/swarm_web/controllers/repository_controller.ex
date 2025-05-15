defmodule SwarmWeb.RepositoryController do
  use SwarmWeb, :controller
  use SwarmWeb.Auth.CurrentResource

  alias Swarm.Repositories

  action_fallback SwarmWeb.FallbackController

  def index(conn, _params, user) do
    repositories = Repositories.list_repositories(user)
    render(conn, :index, repositories: repositories)
  end

  def create(conn, %{"repository" => params}, user) do
    with {:ok, repository} <- Repositories.create_repository(user, params) do
      conn
      |> put_status(:created)
      |> render(:show, repository: repository)
    end
  end
end
