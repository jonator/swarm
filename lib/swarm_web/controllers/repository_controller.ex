defmodule SwarmWeb.RepositoryController do
  use SwarmWeb, :controller
  use SwarmWeb.Auth.CurrentResource

  alias Swarm.Repositories
  alias Swarm.Services

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

  def create(conn, %{"github_repo_id" => github_repo_id, "projects" => project_attrs}, user) do
    with {:ok, repository} <-
           Services.create_repository_from_github(user, github_repo_id, project_attrs) do
      conn
      |> put_status(:created)
      |> render(:show, repository: repository)
    end
  end

  def create(conn, %{"github_repo_id" => github_repo_id}, user) do
    with {:ok, repository} <-
           Services.create_repository_from_github(user, github_repo_id) do
      conn
      |> put_status(:created)
      |> render(:show, repository: repository)
    end
  end

  def create(conn, _params, _user) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{params: ["repository or github_repo_id is required"]}})
  end

  def update(conn, %{"id" => id} = attrs, user) do
    with {:ok, repository} <- Repositories.update_repository(user, id, attrs) do
      conn
      |> put_status(:ok)
      |> render(:show, repository: repository)
    end
  end
end
