defmodule SwarmWeb.AgentController do
  use SwarmWeb, :controller
  use SwarmWeb.Auth.CurrentResource
  import Phoenix.Sync.Controller
  import Ecto.Query, only: [from: 2]

  alias Swarm.Agents.Agent

  action_fallback SwarmWeb.FallbackController

  def show(conn, %{"repository_id" => repository_id} = params, user) do
    user_repos = Swarm.Repositories.list_repositories(user)

    case Enum.find(user_repos, &(&1.id == repository_id)) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Repository not found"})

      repo ->
        sync_render(conn, params, from(r in Agent, where: r.repository_id == ^repo.id))
    end
  end
end
