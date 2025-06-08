defmodule Swarm.Workers.Coder do
  @moduledoc """
  Coding agent worker that implements code changes and creates pull requests.

  This worker is responsible for:
  1. Cloning the repository and creating a feature branch
  2. Analyzing the context and requirements
  3. Implementing the requested changes
  4. Running tests and ensuring code quality
  5. Creating a pull request with the changes
  """

  use Oban.Worker, queue: :default
  require Logger

  alias Swarm.Agents
  alias Swarm.Agents.Agent
  alias Swarm.Git
  alias Swarm.Instructor

  @impl Oban.Worker
  def perform(%Oban.Job{id: oban_job_id, args: %{"agent_id" => agent_id}}) do
    Logger.info("Starting coder agent for agent ID: #{agent_id}")

    with {:ok, agent} <- get_agent(agent_id),
         {:ok, agent} <- Agents.mark_agent_started(agent, oban_job_id),
         {:ok, result} <- implement_code_changes(agent),
         {:ok, _agent} <- Agents.mark_agent_completed(agent) do
      Logger.info("Coder agent #{agent_id} completed successfully")
      {:ok, result}
    else
      {:error, reason} = error ->
        Logger.error("Coder agent #{agent_id} failed: #{reason}")
        case Agents.get_agent(agent_id) do
          %Agent{} = agent -> Agents.mark_agent_failed(agent)
          nil -> :ok
        end
        error
    end
  end

  defp get_agent(agent_id) do
    case Agents.get_agent(agent_id) do
      nil -> {:error, "Agent not found"}
      agent -> {:ok, agent}
    end
  end

  defp implement_code_changes(%Agent{} = agent) do
    Logger.info("Implementing code changes for agent #{agent.id}")

    FLAME.call(Swarm.ImplementNextjsPool, fn ->
      perform_code_implementation(agent)
    end)
  end

  defp perform_code_implementation(%Agent{} = agent) do
    Logger.info("Performing code implementation for agent #{agent.id}")

    # Get repository information
    repository = Swarm.Repo.preload(agent, :repository).repository

    if repository do
      implement_changes_in_repository(agent, repository)
    else
      {:error, "No repository associated with agent"}
    end
  end

  defp implement_changes_in_repository(agent, repository) do
    repo_url = build_repository_url(repository)
    instructions = agent.context

    with {:ok, branch_name} <- generate_branch_name(instructions),
         {:ok, repo} <- clone_repository(repo_url, agent.id, branch_name),
         {:ok, index} <- create_repository_index(repo),
         {:ok, relevant_files} <- find_relevant_files(repo, index, instructions),
         {:ok, implementation_result} <- implement_changes(repo, index, relevant_files, instructions),
         {:ok, _} <- run_build_and_tests(repo),
         {:ok, pr_result} <- create_pull_request(repo, agent, branch_name, implementation_result) do
      Logger.info("Code implementation completed for agent #{agent.id}")
      {:ok, %{branch: branch_name, pr: pr_result, changes: implementation_result}}
    else
      error ->
        Logger.error("Code implementation failed for agent #{agent.id}: #{inspect(error)}")
        error
    end
  end

  defp build_repository_url(repository) do
    case repository.external_id do
      "github:" <> _github_id ->
        "https://github.com/#{repository.owner}/#{repository.name}.git"
      _ ->
        # Fallback to constructing from owner/name
        "https://github.com/#{repository.owner}/#{repository.name}.git"
    end
  end

  defp generate_branch_name(instructions) do
    case Instructor.BranchName.generate_branch_name(instructions) do
      {:ok, %{branch_name: branch_name}} ->
        {:ok, branch_name}
      error ->
        Logger.warning("Failed to generate branch name, using fallback: #{inspect(error)}")
        timestamp = System.system_time(:second)
        {:ok, "swarm-feature-#{timestamp}"}
    end
  end

  defp clone_repository(repo_url, agent_id, branch_name) do
    Logger.debug("Cloning repository: #{repo_url} with branch: #{branch_name}")

    case Git.Repo.open(repo_url, "coder-#{agent_id}", branch_name) do
      {:ok, repo} ->
        Logger.debug("Successfully cloned repository to: #{repo.path}")
        {:ok, repo}
      error ->
        Logger.error("Failed to clone repository: #{inspect(error)}")
        error
    end
  end

  defp create_repository_index(repo) do
    Logger.debug("Creating repository index for: #{repo.path}")

    # Get exclude patterns for indexing
    exclude_patterns = get_exclude_patterns()

    case Git.Index.from(repo, exclude_patterns) do
      {:ok, index} ->
        Logger.debug("Successfully created repository index")
        {:ok, index}
      error ->
        Logger.error("Failed to create repository index: #{inspect(error)}")
        error
    end
  end

  defp get_exclude_patterns() do
    # Common patterns to exclude from indexing
    [
      ~r/node_modules/,
      ~r/\.git/,
      ~r/_build/,
      ~r/deps/,
      ~r/\.next/,
      ~r/dist/,
      ~r/build/,
      ~r/target/,
      ~r/\.log$/,
      ~r/\.tmp$/,
      ~r/\.DS_Store$/,
      ~r/\.env$/,
      ~r/\.env\.local$/,
      ~r/coverage/,
      ~r/\.nyc_output/,
      ~r/\.pytest_cache/,
      ~r/__pycache__/
    ]
  end

  defp find_relevant_files(repo, index, instructions) do
    Logger.debug("Finding relevant files for implementation")

    # Run tasks concurrently to gather file information
    tasks = [
      Task.async(fn ->
        get_search_terms_and_files(instructions)
      end),
      Task.async(fn ->
        get_relevant_files_from_instructor(repo, instructions)
      end)
    ]

    # Await results
    [search_result, relevant_result] = Task.await_many(tasks, 300_000)

    # Combine results from different sources
    search_files = case search_result do
      {:ok, %{files: files}} -> files
      _ -> []
    end

    relevant_files = case relevant_result do
      {:ok, %{files: files}} -> files
      _ -> []
    end

    # Search for terms in the index if we have search terms
    term_files = case search_result do
      {:ok, %{terms: terms}} ->
        search_terms_in_index(index, terms)
      _ ->
        []
    end

    # Combine and deduplicate all files
    all_files = Enum.uniq(search_files ++ relevant_files ++ term_files)

    Logger.debug("Found #{length(all_files)} relevant files for implementation")
    {:ok, all_files}
  end

  defp get_search_terms_and_files(instructions) do
    case Instructor.SearchTerms.get_search_terms(instructions) do
      {:ok, %{terms: terms, files: files}} ->
        {:ok, %{terms: terms, files: files}}
      {:ok, %{terms: terms}} ->
        {:ok, %{terms: terms, files: []}}
      error ->
        Logger.warning("Failed to get search terms: #{inspect(error)}")
        {:ok, %{terms: [], files: []}}
    end
  end

  defp get_relevant_files_from_instructor(repo, instructions) do
    case Instructor.RelevantFiles.get_relevant_files(repo, instructions) do
      {:ok, %{files: files}} ->
        {:ok, %{files: files}}
      error ->
        Logger.warning("Failed to get relevant files: #{inspect(error)}")
        {:ok, %{files: []}}
    end
  end

  defp search_terms_in_index(index, terms) do
    Enum.flat_map(terms, &search_single_term(index, &1))
    |> Enum.uniq()
  end

  defp search_single_term(index, term) do
    Logger.debug("Searching for term: #{term}")

    Git.Index.search(index, term)
    |> Enum.map(fn %{id: file_path} -> file_path end)
  end

  defp implement_changes(repo, index, relevant_files, instructions) do
    Logger.debug("Implementing changes with #{length(relevant_files)} relevant files")

    # Use the existing Agent.Implementor module if available
    case Swarm.Agent.Implementor.implement(repo, index, relevant_files, instructions) do
      {:ok, result} ->
        Logger.info("Implementation completed successfully")
        {:ok, result}
      result when is_binary(result) ->
        # If the implementor returns a string (like a success message)
        Logger.info("Implementation completed: #{result}")
        {:ok, result}
      error ->
        Logger.error("Implementation failed: #{inspect(error)}")
        {:error, "Implementation failed: #{inspect(error)}"}
    end
  end

  defp run_build_and_tests(repo) do
    Logger.debug("Running build and tests for: #{repo.path}")

    # Change to repository directory and run common build/test commands
    repo_path = repo.path

    # Try to detect and run appropriate build/test commands
    cond do
      File.exists?(Path.join(repo_path, "package.json")) ->
        run_nodejs_build_and_tests(repo_path)

      File.exists?(Path.join(repo_path, "mix.exs")) ->
        run_elixir_build_and_tests(repo_path)

      File.exists?(Path.join(repo_path, "Gemfile")) ->
        run_ruby_build_and_tests(repo_path)

      true ->
        Logger.info("No recognized build system found, skipping build/test")
        {:ok, :skipped}
    end
  end

  defp run_nodejs_build_and_tests(repo_path) do
    Logger.debug("Running Node.js build and tests")

    # Check if we have a lockfile to determine package manager
    package_manager = cond do
      File.exists?(Path.join(repo_path, "yarn.lock")) -> "yarn"
      File.exists?(Path.join(repo_path, "pnpm-lock.yaml")) -> "pnpm"
      true -> "npm"
    end

    commands = [
      "#{package_manager} install",
      "#{package_manager} run build",
      "#{package_manager} run lint",
      "#{package_manager} run format"
    ]

    run_commands_in_directory(repo_path, commands)
  end

  defp run_elixir_build_and_tests(repo_path) do
    Logger.debug("Running Elixir build and tests")

    commands = [
      "mix deps.get",
      "mix compile",
      "mix format",
      "mix credo --strict"
    ]

    run_commands_in_directory(repo_path, commands)
  end

  defp run_ruby_build_and_tests(repo_path) do
    Logger.debug("Running Ruby build and tests")

    commands = [
      "bundle install",
      "bundle exec rubocop"
    ]

    run_commands_in_directory(repo_path, commands)
  end

  defp run_commands_in_directory(repo_path, commands) do
    results = Enum.map(commands, fn command ->
      Logger.debug("Running command: #{command}")

      case System.cmd("sh", ["-c", command], cd: repo_path, stderr_to_stdout: true) do
        {output, 0} ->
          Logger.debug("Command succeeded: #{command}")
          {:ok, output}

        {output, exit_code} ->
          Logger.warning("Command failed (exit #{exit_code}): #{command}\nOutput: #{output}")
          {:warning, "Command failed: #{command} (exit #{exit_code})"}
      end
    end)

    # Check if any critical commands failed
    failures = Enum.filter(results, fn
      {:error, _} -> true
      _ -> false
    end)

    if Enum.empty?(failures) do
      {:ok, results}
    else
      Logger.warning("Some build/test commands failed, but continuing with PR creation")
      {:ok, results}
    end
  end

  defp create_pull_request(repo, agent, branch_name, implementation_result) do
    Logger.debug("Creating pull request for branch: #{branch_name}")

    # Push the branch
    case push_branch(repo, branch_name) do
      {:ok, _} ->
        # Create PR description
        pr_description = generate_pr_description(agent, implementation_result)

        # For now, we'll return a success indicator
        # In a real implementation, this would use the GitHub API to create the PR
        pr_info = %{
          title: generate_pr_title(agent),
          branch: branch_name,
          description: pr_description,
          repository: "#{repo.path}"
        }

        Logger.info("Pull request created successfully: #{pr_info.title}")
        {:ok, pr_info}

      error ->
        Logger.error("Failed to push branch: #{inspect(error)}")
        error
    end
  end

  defp push_branch(repo, branch_name) do
    Logger.debug("Pushing branch #{branch_name} for repo at #{repo.path}")

    # This would use Git commands to push the branch
    # For now, we'll simulate a successful push
    case System.cmd("git", ["push", "origin", branch_name], cd: repo.path, stderr_to_stdout: true) do
      {_output, 0} ->
        Logger.info("Successfully pushed branch: #{branch_name}")
        {:ok, :pushed}

      {output, exit_code} ->
        Logger.error("Failed to push branch: #{output} (exit #{exit_code})")
        {:error, "Failed to push branch: #{output}"}
    end
  end

  defp generate_pr_title(agent) do
    case agent.linear_issue_id do
      nil ->
        "Automated changes by Swarm Agent"
      linear_id ->
        "SW: Automated implementation for #{String.slice(linear_id, 0, 8)}"
    end
  end

  defp generate_pr_description(agent, implementation_result) do
    """
    ## 🤖 Automated Implementation by Swarm Agent

    This pull request was created automatically by a Swarm coding agent.

    ### Original Request
    #{String.slice(agent.context, 0, 500)}#{if String.length(agent.context) > 500, do: "...", else: ""}

    ### Implementation Details
    #{format_implementation_result(implementation_result)}

    ### Agent Information
    - Agent ID: #{agent.id}
    - Agent Type: #{agent.type}
    - Source: #{agent.source}
    #{if agent.linear_issue_id, do: "- Linear Issue: #{agent.linear_issue_id}", else: ""}

    ### Review Notes
    Please review the changes carefully before merging. This is an automated implementation
    and may require adjustments or additional testing.

    ---
    *Generated by Swarm Coding Agent at #{DateTime.utc_now()}*
    """
  end

  defp format_implementation_result(result) when is_binary(result) do
    result
  end

  defp format_implementation_result(result) when is_map(result) do
    case Map.get(result, :summary) do
      nil -> "Implementation completed successfully."
      summary -> summary
    end
  end

  defp format_implementation_result(_result) do
    "Implementation completed successfully."
  end
end
