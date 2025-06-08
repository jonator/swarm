defmodule Swarm.Workers do

  alias Swarm.Ingress.Event
  alias Swarm.Egress

  def spawn(_agent_attrs, %Event{} = event) do
    with {:ok, msg} <- Egress.acknowledge(event) do
      {:ok, msg}
    end
  end
end
