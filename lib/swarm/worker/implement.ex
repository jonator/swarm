defmodule Swarm.Worker.Implement do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{"url" => url, "branch" => branch, "instructions" => instructions}
      }) do
    {:ok, repo} = Swarm.Git.Repo.open(url, to_string(id), branch)

    get_relevant_file_list(repo, instructions)

    :ok
  end

  defp get_relevant_file_list(%Swarm.Git.Repo{} = repo, instructions) do
    # Run tasks concurrently
    tasks = [
      Task.async(fn ->
        Swarm.Instructor.SearchTerms.get_search_terms(instructions)
      end),
      Task.async(fn ->
        Swarm.Instructor.RelevantFiles.get_relevant_files(repo, instructions)
      end),
      Task.async(fn ->
        Swarm.Git.Index.from(repo)
      end)
    ]

    # Await results
    [{:ok, %{terms: terms, files: search_files}}, {:ok, %{files: relevant_files}}, {:ok, index}] =
      Task.await_many(tasks, 25_000)

    IO.inspect(search_files, label: "SEARCH FILES")
    IO.inspect(relevant_files, label: "RELEVANT FILES")
    # Search for each term in the index
    term_results =
      Enum.flat_map(terms, fn term ->
        IO.inspect(term, label: "TERM")
        results = Swarm.Git.Index.search(index, term)
        Enum.map(results, fn %{id: file_path} -> file_path end)
      end)
      |> Enum.uniq()

    # Combine files from both sources
    all_files = Enum.uniq(search_files ++ relevant_files ++ term_results)

    # For debugging purposes
    IO.inspect(all_files, label: "RESULT FILES, LENGTH: #{length(term_results)}")

    # Return the compiled list of files
    all_files
  end
end
