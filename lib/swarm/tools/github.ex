defmodule Swarm.Tools.Github do
  @moduledoc false

  alias LangChain.Function
  alias LangChain.FunctionParam

  def all_tools do
    [
      create_pr()
    ]
  end

  def create_pr do
    Function.new!(%{
      name: "create_pr",
      description: "Creates a pull request for the current branch.",
      parameters: [],
      function: fn _arguments, %{"repo" => repo} ->
        Swarm.Github.create_pr(repo)
      end
    })
  end
end
