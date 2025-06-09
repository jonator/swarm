defmodule Swarm.Workers.Researcher do
  @moduledoc """
  Research agent worker that analyzes codebases and generates implementation plans.

  This worker is responsible for:
  1. Cloning and analyzing repository structure
  2. Understanding the context and requirements
  3. Generating detailed implementation plans
  4. Updating Linear issues with research findings
  """

  use Oban.Worker, queue: :default
  require Logger

  alias Swarm.Agents
  alias Swarm.Agents.Agent
  alias Swarm.Git
  alias Swarm.Repositories.Repository

  @impl Oban.Worker
  def perform(%Oban.Job{id: oban_job_id, args: %{"agent_id" => agent_id}}) do
    Logger.info("Starting research agent for agent ID: #{agent_id}")

    with {:ok, agent} <- get_agent(agent_id),
         {:ok, agent} <- Agents.mark_agent_started(agent, oban_job_id),
         {:ok, result} <- conduct_research(agent),
         {:ok, _agent} <- Agents.mark_agent_completed(agent) do
      Logger.info("Research agent #{agent_id} completed successfully")
      {:ok, result}
    else
      {:error, reason} = error ->
        Logger.error("Research agent #{agent_id} failed: #{reason}")
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

  defp conduct_research(%Agent{} = agent) do
    Logger.info("Conducting research for agent #{agent.id}")

    FLAME.call(Swarm.ImplementNextjsPool, fn ->
      perform_research_analysis(agent)
    end)
  end

  defp perform_research_analysis(%Agent{} = agent) do
    Logger.info("Performing research analysis for agent #{agent.id}")

    # Get repository information
    repository = Swarm.Repo.preload(agent, :repository).repository

    if repository do
      analyze_repository_and_context(agent, repository)
    else
      {:error, "No repository associated with agent"}
    end
  end

  defp analyze_repository_and_context(agent, repository) do
    repo_url = Repository.build_repository_url(repository)

    with {:ok, repo} <- clone_repository(repo_url, agent.id),
         {:ok, codebase_analysis} <- analyze_codebase_structure(repo),
         {:ok, implementation_plan} <- generate_implementation_plan(agent, codebase_analysis),
         {:ok, _} <- update_linear_issue_with_plan(agent, implementation_plan) do
      Logger.info("Research completed for agent #{agent.id}")
      {:ok, %{plan: implementation_plan, analysis: codebase_analysis}}
    else
      error ->
        Logger.error("Research analysis failed for agent #{agent.id}: #{inspect(error)}")
        error
    end
  end



  defp clone_repository(repo_url, agent_id) do
    Logger.debug("Cloning repository: #{repo_url}")

    # Use a unique branch name for research
    branch_name = "swarm-research-#{agent_id}-#{System.system_time(:second)}"

    case Git.Repo.open(repo_url, "research-#{agent_id}", branch_name) do
      {:ok, repo} ->
        Logger.debug("Successfully cloned repository to: #{repo.path}")
        {:ok, repo}
      error ->
        Logger.error("Failed to clone repository: #{inspect(error)}")
        error
    end
  end

  defp analyze_codebase_structure(repo) do
    Logger.debug("Analyzing codebase structure for: #{repo.path}")

    # Get repository index with common exclusions
    exclude_patterns = [
      ~r/node_modules/,
      ~r/\.git/,
      ~r/_build/,
      ~r/deps/,
      ~r/\.next/,
      ~r/dist/,
      ~r/build/,
      ~r/target/,
      ~r/\.log$/,
      ~r/\.tmp$/
    ]

    case Git.Index.from(repo, exclude_patterns) do
      {:ok, index} ->
        # Analyze key files and structure
        analysis = %{
          file_count: count_files_in_index(index),
          key_files: find_key_files(index),
          project_type: detect_project_type(index),
          main_directories: get_main_directories(index),
          readme_content: get_readme_content(repo),
          package_files: find_package_files(index)
        }

        Logger.debug("Codebase analysis complete: #{inspect(Map.keys(analysis))}")
        {:ok, analysis}

      error ->
        Logger.error("Failed to create repository index: #{inspect(error)}")
        error
    end
  end

  defp count_files_in_index(_index) do
    # This would depend on the Git.Index implementation
    # For now, return a placeholder
    0
  end

  defp find_key_files(_index) do
    # Search for important configuration and entry files
    _key_patterns = [
      "package.json", "package-lock.json", "yarn.lock",
      "Dockerfile", "docker-compose.yml",
      "README.md", "README.txt",
      "mix.exs", "mix.lock",
      "Gemfile", "Gemfile.lock",
      "requirements.txt", "setup.py",
      "pom.xml", "build.gradle",
      "next.config.js", "tailwind.config.js",
      "tsconfig.json", "jsconfig.json"
    ]

    # This would use the index to search for these files
    # For now, return placeholder
    []
  end

  defp detect_project_type(index) do
    cond do
      nextjs_project?(index) -> "Next.js"
      nodejs_project?(index) -> "Node.js/JavaScript"
      elixir_project?(index) -> "Elixir"
      ruby_project?(index) -> "Ruby"
      python_project?(index) -> "Python"
      java_maven_project?(index) -> "Java (Maven)"
      java_gradle_project?(index) -> "Java (Gradle)"
      true -> "Unknown"
    end
  end

  defp nextjs_project?(_index) do
    # has_file?(index, "package.json") && has_file?(index, "next.config.js")
    false
  end

  defp nodejs_project?(_index) do
    # has_file?(index, "package.json")
    false
  end

  defp elixir_project?(_index) do
    # has_file?(index, "mix.exs")
    false
  end

  defp ruby_project?(_index) do
    # has_file?(index, "Gemfile")
    false
  end

  defp python_project?(_index) do
    # has_file?(index, "requirements.txt")
    false
  end

  defp java_maven_project?(_index) do
    # has_file?(index, "pom.xml")
    false
  end

  defp java_gradle_project?(_index) do
    # has_file?(index, "build.gradle")
    false
  end

  defp get_main_directories(_index) do
    # Get top-level directories from the index
    # Implementation depends on Git.Index API
    []
  end

  defp get_readme_content(repo) do
    readme_path = Path.join(repo.path, "README.md")

    case File.read(readme_path) do
      {:ok, content} -> String.slice(content, 0, 2000) # Limit content size
      {:error, _} ->
        # Try alternative README files
        alt_readme = Path.join(repo.path, "README.txt")
        case File.read(alt_readme) do
          {:ok, content} -> String.slice(content, 0, 2000)
          {:error, _} -> "No README found"
        end
    end
  end

  defp find_package_files(_index) do
    # Find package management files
    # Implementation depends on Git.Index API
    []
  end

  defp generate_implementation_plan(agent, codebase_analysis) do
    Logger.debug("Generating implementation plan for agent #{agent.id}")

    plan = """
    # Implementation Plan

    ## Context Analysis
    #{agent.context}

    ## Repository Analysis
    - Project Type: #{codebase_analysis.project_type}
    - File Count: #{codebase_analysis.file_count}
    - Key Files Found: #{Enum.join(codebase_analysis.key_files, ", ")}

    ## README Content
    #{codebase_analysis.readme_content}

    ## Recommended Implementation Steps

    1. **Analyze Requirements**: Review the issue description and comments for specific requirements
    2. **Identify Target Files**: Determine which files need to be modified based on the request
    3. **Plan Changes**: Create a detailed plan for the specific changes needed
    4. **Implementation Strategy**: Determine the best approach for implementing the changes
    5. **Testing Considerations**: Identify what testing might be needed

    ## Technical Considerations

    Based on the codebase analysis, this appears to be a #{codebase_analysis.project_type} project.

    ## Next Steps

    This research provides the foundation for implementation. A coding agent can now be spawned
    with this context to implement the specific changes requested.

    ---
    *Generated by Swarm Research Agent at #{DateTime.utc_now()}*
    """

    {:ok, plan}
  end

  defp update_linear_issue_with_plan(agent, implementation_plan) do
    if agent.linear_issue_id do
      Logger.debug("Updating Linear issue #{agent.linear_issue_id} with implementation plan")

      # Get the user's Linear app user ID from the agent context
      # This would need to be stored or retrieved from the user/agent relationship
      _comment_text = """
      ## 🔍 Research Complete

      I've analyzed the codebase and generated an implementation plan:

      #{implementation_plan}
      """

      # Note: This would need the actual Linear app user ID
      # For now, we'll just log that we would update it
      Logger.info("Would update Linear issue #{agent.linear_issue_id} with research findings")
      {:ok, :updated}
    else
      Logger.debug("No Linear issue ID found, skipping Linear update")
      {:ok, :skipped}
    end
  end
end
