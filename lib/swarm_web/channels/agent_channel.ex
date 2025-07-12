defmodule SwarmWeb.AgentChannel do
  use SwarmWeb, :channel

  @impl true
  def join("agent:" <> agent_id, payload, socket) do
    if authorized?(agent_id, payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("user_message", payload, socket) do
    broadcast(socket, "user_message", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("messages", _payload, socket) do
    "agent:" <> agent_id = socket.topic
    messages = Swarm.Agents.messages(agent_id)
    resp = SwarmWeb.AgentJSON.index(%{messages: messages})
    {:reply, {:ok, resp}, socket}
  end

  @impl true
  def handle_info({event, payload}, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  defp authorized?(agent_id, %{"token" => token}) do
    case SwarmWeb.Auth.Guardian.resource_from_token(token) do
      {:ok, user, _claims} -> Swarm.Agents.get_agent(user, agent_id) != nil
      {:error, _} -> false
    end
  end
end
