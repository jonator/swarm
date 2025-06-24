defmodule SwarmWeb.AgentController do
  use SwarmWeb, :controller
  use SwarmWeb.Auth.CurrentResource

  alias Swarm.Agents

  action_fallback SwarmWeb.FallbackController

  def index(conn, params, user) do
    agents = Agents.list_agents(user, params)
    render(conn, :index, agents: agents)
  end
end
