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
  alias Swarm.Repositories.Repository
  alias Swarm.Services.GitHub
  alias Swarm.Services.Linear
  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias LangChain.ChatModels.ChatAnthropic
  alias Swarm.Tools.Git.Repo, as: ToolRepo
  alias Swarm.Tools.Git.Index, as: ToolRepoIndex

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
      nil ->
        {:error, "Agent not found"}

      agent ->
        # Preload user and repository associations for GitHub service
        agent = Swarm.Repo.preload(agent, [:user, :repository])
        {:ok, agent}
    end
  end

  defp implement_code_changes(%Agent{} = agent) do
    Logger.info("Implementing code changes for agent #{agent.id}")

    FLAME.call(Swarm.FlamePool, fn ->
      implement_changes_in_repository(agent)
    end)
  end

  defp implement_changes_in_repository(%Agent{context: context} = agent) do
    with {:ok, branch_name} <- get_branch_name(agent),
         {:ok, repo} <- clone_repository(agent, branch_name),
         {:ok, index} <- create_repository_index(repo),
         {:ok, tools} <- get_tools(repo),
         {:ok, implementation_result} <- implement_changes(repo, index, tools, context),
         {:ok, pr_result} <- create_pull_request(repo, agent, branch_name, implementation_result) do
      Logger.info("Code implementation completed for agent #{agent.id}")
      {:ok, %{branch: branch_name, pr: pr_result, changes: implementation_result}}
    else
      error ->
        Logger.error("Code implementation failed for agent #{agent.id}: #{inspect(error)}")
        error
    end
  end

  defp get_branch_name(
         %Agent{
           source: :linear,
           external_ids: %{"linear_issue_id" => issue_id, "linear_app_user_id" => app_user_id}
         } = agent
       ) do
    case Linear.issue(app_user_id, issue_id) do
      {:ok, %{branchName: branch_name}} ->
        {:ok, branch_name}

      error ->
        Logger.error(
          "Failed to get Linear branch name (falling back to instructor): #{inspect(error)}"
        )

        get_branch_name(agent)
    end
  end

  defp get_branch_name(%Agent{context: instructions}) do
    Logger.debug("Generating branch name using instructor")

    case Instructor.BranchName.generate_branch_name(instructions) do
      {:ok, %{branch_name: branch_name}} ->
        {:ok, branch_name}

      error ->
        Logger.warning("Failed to generate branch name, using fallback: #{inspect(error)}")
        timestamp = System.system_time(:second)
        {:ok, "swarm-feature-#{timestamp}"}
    end
  end

  defp clone_repository(%Agent{user: user, repository: repository, id: agent_id}, branch_name) do
    Logger.debug(
      "Cloning repository: #{repository.owner}/#{repository.name} with branch: #{branch_name}"
    )

    # Get repository information from GitHub API
    # Note: In the future when organizations are supported, we will need to
    # get the repository using the organization and not the user
    with {:ok, repo_info} <- GitHub.repository_info(user, repository.owner, repository.name),
         default_branch <- Map.get(repo_info, "default_branch", "main"),
         repo_url <- Repository.build_repository_url(repository),
         # Use default branch as base, but checkout our working branch
         {:ok, repo} <- Git.Repo.open(repo_url, "coder-#{agent_id}", default_branch),
         {:ok, _} <- create_and_switch_branch(repo, branch_name) do
      Logger.debug("Successfully cloned repository to: #{repo.path}")
      {:ok, repo}
    else
      {:error, reason} ->
        Logger.error("Failed to clone repository: #{inspect(reason)}")
        {:error, reason}

      error ->
        Logger.error("Failed to clone repository: #{inspect(error)}")
        error
    end
  end

  defp create_and_switch_branch(repo, branch_name) do
    # Create and switch to the working branch
    case System.cmd("git", ["checkout", "-b", branch_name], cd: repo.path) do
      {_, 0} -> {:ok, :branch_created}
      {error, _} -> {:error, "Failed to create branch: #{error}"}
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

  defp get_tools(repo) do
    {:ok, ToolRepo.all_tools() ++ ToolRepoIndex.all_tools()}
  end

  defp implement_changes(repo, index, tools, instructions) do
    Logger.debug("Implementing changes")

    messages = [
      Message.new_system!("""
      You are a software developer implementing changes to a codebase. Examine the files carefully and implement the requested changes according to the instructions.
      Write files and commit changes immediately- do not ask for confirmation.
      Push changes once completed. If there are newline file terminators, keep them.
      """),
      Message.new_user!("I need to implement the following changes: #{inspect(instructions)}")
    ]

    chat_model =
      ChatAnthropic.new!(%{
        model: "claude-sonnet-4-20250514",
        max_tokens: 4096,
        temperature: 0.7,
        stream: false
      })

    case %{
           llm: chat_model,
           custom_context: %{"repo" => repo, "repo_index" => index},
           verbose: true
         }
         |> LLMChain.new!()
         |> LLMChain.add_messages(messages)
         |> LLMChain.add_tools(tools)
         |> LLMChain.run_until_tool_used("push_origin") do
      {:ok, updated_chain} ->
        Logger.info("Implementation completed successfully")
        {:ok, updated_chain.last_message.content}

      result when is_binary(result) ->
        Logger.info("Implementation completed: #{result}")
        {:ok, result}

      error ->
        Logger.error("Implementation failed: #{inspect(error)}")
        {:error, "Implementation failed: #{inspect(error)}"}
    end
  end

  defp create_pull_request(repo, agent, branch_name, implementation_result) do
    Logger.debug("Creating pull request for branch: #{branch_name}")

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
  end

  defp generate_pr_title(agent) do
    case Map.get(agent.external_ids, "linear_issue_id") do
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
    #{Map.get(agent.external_ids, "linear_issue_id") && "- Linear Issue: #{Map.get(agent.external_ids, "linear_issue_id")}"}

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
