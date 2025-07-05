defmodule SwarmWeb.AgentChannel do
  use SwarmWeb, :channel
  alias Phoenix.Socket.Broadcast

  @impl true
  def join("agent:" <> agent_id, payload, socket) do
    if authorized?(agent_id, payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("user_msg", payload, socket) do
    broadcast(socket, "user_msg", payload)
    {:noreply, socket}
  end

  @impl true
  @spec handle_info(Phoenix.Socket.Broadcast.t(), Phoenix.Socket.t()) ::
          {:noreply, Phoenix.Socket.t()}
  def handle_info(%Broadcast{topic: _, event: event, payload: payload}, socket) do
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
