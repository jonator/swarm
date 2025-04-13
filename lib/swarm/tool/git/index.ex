defmodule Swarm.Tool.Git.Index do
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
      function: fn %{"query" => query} = _arguments, %{"repo_index" => repo_index} ->
        case Swarm.Git.Index.search(repo_index, query) do
          [] ->
            "No results found for query: #{query}"

          results ->
            results
            |> Enum.map(fn %{id: id} -> id end)
            |> Enum.join("\n")
        end
      end
    })
  end
end
