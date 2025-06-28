defmodule Swarm.Egress do
  @moduledoc """
  Deprecated: Egress module for sending messages or data to external systems.
  Use Swarm.Tools for all tool-based integrations.
  """

  @doc """
  Deprecated. Use Swarm.Tools for tool-based acknowledge.
  """
  def acknowledge(_event, _repository) do
    {:error, "Egress.acknowledge/2 is deprecated. Use Swarm.Tools for tool-based acknowledge."}
  end

  @doc """
  Deprecated. Use Swarm.Tools for tool-based reply.
  """
  def reply(_external_ids, _message) do
    {:error, "Egress.reply/2 is deprecated. Use Swarm.Tools for tool-based reply."}
  end
end
