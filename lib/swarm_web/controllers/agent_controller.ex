defmodule SwarmWeb.AgentController do
  use SwarmWeb, :controller
  use SwarmWeb.Auth.CurrentResource

  alias Swarm.Agents

  action_fallback SwarmWeb.FallbackController

  def index(conn, params, user) do
    agents = Agents.list_agents(user, params)
    render(conn, :index, agents: agents)
  end

  def show(conn, %{"id" => id}, user) do
    case Agents.get_agent(user, id) do
      nil ->
        send_resp(conn, :not_found, "Not found")

      agent ->
        render(conn, :show, agent: agent)
    end
  end
end
