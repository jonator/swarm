defmodule Swarm.Tools do
  @moduledoc """
  Provides a function to select the appropriate set of tools for a given agent.
  """

  alias Swarm.Agents.Agent

  # Note: LangChain will error if tool names are not unique

  def for_agent(agent, mode \\ :read_write)

  def for_agent(%Agent{source: :github}, mode),
    do: Swarm.Tools.Git.all_tools(mode) ++ Swarm.Tools.GitHub.all_tools(mode)

  def for_agent(%Agent{source: :linear}, mode) do
    git_tools = Swarm.Tools.Git.all_tools(mode)
    linear_tools = Swarm.Tools.Linear.all_tools(mode)
    github_tools = Swarm.Tools.GitHub.all_tools(mode)

    # Return github_tools that are not in linear_tools
    filtered_github_tools =
      github_tools
      |> Enum.filter(fn github_tool ->
        not Enum.any?(linear_tools, fn linear_tool -> linear_tool.name == github_tool.name end)
      end)

    git_tools ++ filtered_github_tools ++ linear_tools
  end

  def for_agent(%Agent{source: :manual}, mode),
    do:
      Swarm.Tools.Git.all_tools(mode) ++
        Swarm.Tools.GitHub.all_tools(mode) ++ Swarm.Tools.Linear.all_tools(mode)

  def for_agent(%Agent{source: :slack}, mode),
    do:
      Swarm.Tools.Git.all_tools(mode) ++
        Swarm.Tools.GitHub.all_tools(mode) ++ Swarm.Tools.Linear.all_tools(mode)

  def for_agent(_agent, mode), do: Swarm.Tools.Git.all_tools(mode)
end
