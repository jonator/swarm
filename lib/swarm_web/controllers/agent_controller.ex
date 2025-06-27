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
    agent = Agents.get_agent(user, id)
    render(conn, :show, agent: agent)
  end
end
