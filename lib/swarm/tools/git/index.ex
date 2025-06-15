defmodule Swarm.Tools.Git.Index do
  @moduledoc false

  alias LangChain.Function
  alias LangChain.FunctionParam

  def all_tools do
    [
      search_files()
    ]
  end

  def search_files do
    Function.new!(%{
      name: "search_files",
      description: "Searches the repository files for matching content.",
      parameters: [
        FunctionParam.new!(%{
          name: "query",
          type: :string,
          description: "The search query to find matching content.",
          required: true
        })
      ],
      function: fn %{"query" => query} = _arguments, %{"git_repo_index" => repo_index} ->
        case Swarm.Git.Index.search(repo_index, query) do
          [] ->
            "No results found for query: #{query}"

          results ->
            Enum.map_join(results, "\n", fn %{id: id} -> id end)
        end
      end
    })
  end
end
