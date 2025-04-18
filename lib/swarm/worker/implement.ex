defmodule Swarm.Worker.Implement do
  use Oban.Worker, queue: :default
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{"repo_url" => repo_url, "instructions" => instructions}
      }) do
    case Swarm.Instructor.HasEnoughInstruction.check(instructions) do
      {:ok, %{has_enough: true}} ->
        Logger.debug("Has enough instruction: #{inspect(instructions)}")

        FLAME.call(Swarm.ImplementNextjsPool, fn ->
          implement_instructions(repo_url, id, instructions)
        end)

      {:ok, %{has_enough: false, reason: reason}} ->
        Logger.debug("Insufficient instruction detail: #{reason}")
        :ok

      {:error, error} ->
        Logger.debug("Failed to check instruction: #{inspect(error)}")
        :ok
    end
  end

  defp implement_instructions(repo_url, id, instructions) do
    {:ok, %{branch_name: branch_name}} =
      Swarm.Instructor.BranchName.generate_branch_name(instructions)

    Logger.debug("Branch name: #{branch_name}")
    Logger.debug("Repo URL: #{repo_url}")

    {:ok, repo} = Swarm.Git.Repo.open(repo_url, to_string(id), branch_name)

    Logger.debug("Repo: #{inspect(repo)}")

    # Run tasks concurrently
    tasks = [
      Task.async(fn ->
        Swarm.Instructor.SearchTerms.get_search_terms(instructions)
      end),
      Task.async(fn ->
        Swarm.Instructor.RelevantFiles.get_relevant_files(repo, instructions)
      end),
      Task.async(fn ->
        {:ok, %{patterns: exclude_patterns}} =
          Swarm.Instructor.ExcludeIndexPatterns.get_exclude_patterns(instructions)

        Logger.debug("Exclude patterns: #{inspect(exclude_patterns)}")

        # Compile string patterns into regex patterns
        compiled_patterns =
          Enum.map(exclude_patterns, fn pattern ->
            {:ok, regex} = Regex.compile(pattern)
            regex
          end)

        Swarm.Git.Index.from(repo, compiled_patterns)
      end)
    ]

    # Await results
    [{:ok, %{terms: terms, files: search_files}}, {:ok, %{files: relevant_files}}, {:ok, index}] =
      Task.await_many(tasks, 600_000)

    Logger.debug("Search files: #{inspect(search_files)}")
    Logger.debug("Relevant files: #{inspect(relevant_files)}")
    # Search for each term in the index
    term_results =
      Enum.flat_map(terms, fn term ->
        Logger.debug("Term: #{inspect(term)}")
        results = Swarm.Git.Index.search(index, term)
        Enum.map(results, fn %{id: file_path} -> file_path end)
      end)
      |> Enum.uniq()

    # Combine files from both sources
    all_files = Enum.uniq(search_files ++ relevant_files ++ term_results)

    # For debugging purposes
    Logger.debug("Result files, length: #{length(all_files)}")

    # Return the implementation result
    implementation_result =
      Swarm.Agent.Implementor.implement(repo, index, all_files, instructions)

    # Process the implementation result
    # This could include committing changes, creating a PR, etc.
    # For now, we'll just log the result
    Logger.debug("Implementation completed: #{implementation_result}")
    IO.puts("code #{repo.path}")

    :ok
  end
end
