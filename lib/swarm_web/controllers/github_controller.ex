defmodule SwarmWeb.GitHubController do
  use SwarmWeb, :controller
  use SwarmWeb.Auth.CurrentResource

  alias Swarm.Services.GitHub

  action_fallback SwarmWeb.FallbackController

  def installations(conn, _params, user) do
    with {:ok, installations} <- GitHub.installations(user) do
      conn
      |> put_status(:ok)
      |> json(installations)
    end
  end

  def repositories(conn, _params, user) do
    with {:ok, repositories} <- Swarm.Services.fetch_all_github_repositories(user) do
      conn
      |> put_status(:ok)
      |> json(repositories)
    end
  end

  def trees(conn, %{"owner" => owner, "repo" => repo, "branch" => branch}, user) do
    with {:ok, trees} <- GitHub.repository_trees(user, owner, repo, branch) do
      conn
      |> put_status(:ok)
      |> json(trees)
    end
  end

  def frameworks(conn, %{"owner" => owner, "repo" => repo, "branch" => branch}, user) do
    with {:ok, frameworks} <-
           Swarm.Services.detect_github_repository_frameworks(user, owner, repo, branch) do
      conn
      |> put_status(:ok)
      |> json(frameworks)
    end
  end
end
