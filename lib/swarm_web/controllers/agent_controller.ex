defmodule SwarmWeb.AgentController do
  use SwarmWeb, :controller
  use SwarmWeb.Auth.CurrentResource

  import Phoenix.Sync.Controller
  import Ecto.Query, only: [from: 2]

  alias Swarm.Agents.Agent

  action_fallback SwarmWeb.FallbackController

  def index(conn, %{"repository_id" => repository_id} = params, user) do
    user_repos = Swarm.Repositories.list_repositories(user)
    repository_id = String.to_integer(repository_id)

    case Enum.find(user_repos, &(&1.id == repository_id)) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Repository not found"})

      repo ->
        sync_render(conn, params, from(r in Agent, where: r.repository_id == ^repo.id))
    end
  end

  def index(conn, %{"organization_id" => organization_id} = params, user) do
    user_orgs = Swarm.Organizations.list_organizations(user)
    organization_id = String.to_integer(organization_id)

    case Enum.find(user_orgs, &(&1.id == organization_id)) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Organization not found or not accessible"})

      org ->
        repos = Swarm.Repositories.list_repositories(org)
        repo_ids = Enum.map(repos, & &1.id)
        agents_query = from(a in Agent, where: a.repository_id in ^repo_ids)
        sync_render(conn, params, agents_query)
    end
  end
end
