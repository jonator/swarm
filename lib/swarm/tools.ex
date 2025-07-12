defmodule Swarm.Tools do
  @moduledoc """
  Provides a function to select the appropriate set of tools for a given agent.
  """

  alias Swarm.Agents.Agent

  # Note: LangChain will error if tool names are not unique

  def for_agent(agent, mode \\ :read_write)

  def for_agent(%Agent{source: :github}, mode),
    do: Swarm.Tools.Shell.all_tools(mode)

  def for_agent(%Agent{source: :linear}, mode) do
    shell_tools = Swarm.Tools.Shell.all_tools(mode)
    linear_tools = Swarm.Tools.Linear.all_tools(mode)

    shell_tools ++ linear_tools
  end

  def for_agent(%Agent{source: :manual}, mode),
    do:
      Swarm.Tools.Shell.all_tools(mode) ++
        Swarm.Tools.Linear.all_tools(mode)

  def for_agent(%Agent{source: :slack}, mode),
    do:
      Swarm.Tools.Shell.all_tools(mode) ++
        Swarm.Tools.Linear.all_tools(mode)

  def for_agent(_agent, mode), do: Swarm.Tools.Shell.all_tools(mode)
end
