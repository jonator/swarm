defmodule Swarm.Workers.Coder do
  @moduledoc """
  Coding agent worker that implements code changes and creates pull requests.

  This worker is responsible for:
  1. Cloning the repository and creating a feature branch
  2. Analyzing the context and requirements
  3. Implementing the requested changes
  4. Running tests and ensuring code quality
  5. Creating a pull request with the changes

  The worker uses FLAME for distributed execution and integrates with
  Linear for branch naming and GitHub for repository operations.
  """

  use Oban.Worker, queue: :default
  require Logger

  alias Swarm.Agents
  alias Swarm.Agents.Agent
  alias Swarm.Agents.LLMChain, as: SharedLLMChain
  alias Swarm.Git
  alias Swarm.Instructor
  alias Swarm.Repositories.Repository
  alias Swarm.Services.Linear
  alias LangChain.Chains.LLMChain
  alias LangChain.Message

  @type work_result :: {:ok, map()} | {:error, binary()}

  # Oban Worker Implementation

  @impl Oban.Worker
  def perform(%Oban.Job{id: oban_job_id, args: %{"agent_id" => agent_id}}) do
    Logger.info("Starting coder agent for agent ID: #{agent_id}")

    with {:ok, agent} <- fetch_agent(agent_id),
         {:ok, agent} <- mark_agent_as_started(agent, oban_job_id),
         {:ok, result} <- execute_code_implementation(agent),
         {:ok, _agent} <- mark_agent_as_completed(agent) do
      Logger.info("Coder agent #{agent_id} completed successfully")
      {:ok, result}
    else
      {:error, reason} = error ->
        Logger.error("Coder agent #{agent_id} failed: #{reason}")
        handle_agent_failure(agent_id)
        error
    end
  end

  # Agent Lifecycle Management

  @spec fetch_agent(binary()) :: {:ok, Agent.t()} | {:error, binary()}
  defp fetch_agent(agent_id) do
    case Agents.get_agent(agent_id) do
      nil ->
        {:error, "Agent not found"}

      agent ->
        preloaded_agent = Swarm.Repo.preload(agent, [:user, :repository])
        {:ok, preloaded_agent}
    end
  end

  @spec mark_agent_as_started(Agent.t(), binary()) :: {:ok, Agent.t()} | {:error, any()}
  defp mark_agent_as_started(agent, oban_job_id) do
    Agents.mark_agent_started(agent, oban_job_id)
  end

  @spec mark_agent_as_completed(Agent.t()) :: {:ok, Agent.t()} | {:error, any()}
  defp mark_agent_as_completed(agent) do
    Agents.mark_agent_completed(agent)
  end

  @spec handle_agent_failure(binary()) :: :ok
  defp handle_agent_failure(agent_id) do
    case Agents.get_agent(agent_id) do
      %Agent{} = agent -> Agents.mark_agent_failed(agent)
      nil -> :ok
    end
  end

  # Code Implementation

  @spec execute_code_implementation(Agent.t()) :: work_result()
  defp execute_code_implementation(%Agent{} = agent) do
    Logger.info("Implementing code changes for agent #{agent.id}")

    FLAME.call(Swarm.FlamePool, fn ->
      implement_changes_in_repository(agent)
    end)
  end

  @spec implement_changes_in_repository(Agent.t()) :: work_result()
  defp implement_changes_in_repository(%Agent{} = agent) do
    with {:ok, branch_name} <- determine_branch_name(agent),
         {:ok, git_repo} <- setup_git_repository(agent, branch_name),
         {:ok, git_index} <- create_git_index(git_repo),
         {:ok, implementation_result} <- execute_implementation(agent, git_repo, git_index) do
      Logger.info("Code implementation completed for agent #{agent.id}")
      {:ok, %{branch: branch_name, changes: implementation_result}}
    else
      error ->
        Logger.error("Code implementation failed for agent #{agent.id}: #{inspect(error)}")
        error
    end
  end

  # Branch Name Resolution

  @spec determine_branch_name(Agent.t()) :: {:ok, binary()} | {:error, binary()}
  defp determine_branch_name(%Agent{source: :linear} = agent) do
    case get_linear_branch_name(agent) do
      {:ok, branch_name} -> {:ok, branch_name}
      {:error, _reason} -> generate_fallback_branch_name(agent)
    end
  end

  defp determine_branch_name(%Agent{} = agent) do
    generate_fallback_branch_name(agent)
  end

  @spec get_linear_branch_name(Agent.t()) :: {:ok, binary()} | {:error, any()}
  defp get_linear_branch_name(%Agent{
    external_ids: %{"linear_issue_id" => issue_id, "linear_app_user_id" => app_user_id}
  }) do
    case Linear.issue(app_user_id, issue_id) do
      {:ok, %{"issue" => %{"branchName" => branch_name}}} ->
        {:ok, branch_name}

      error ->
        Logger.error("Failed to get Linear branch name: #{inspect(error)}")
        {:error, "Linear API error"}
    end
  end

  defp get_linear_branch_name(_agent) do
    {:error, "Missing Linear external IDs"}
  end

  @spec generate_fallback_branch_name(Agent.t()) :: {:ok, binary()} | {:error, binary()}
  defp generate_fallback_branch_name(%Agent{context: instructions}) do
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

  # Git Repository Setup

  @spec setup_git_repository(Agent.t(), binary()) :: {:ok, map()} | {:error, binary()}
  defp setup_git_repository(%Agent{repository: repository, id: agent_id}, branch_name) do
    Logger.debug("Cloning repository: #{repository.owner}/#{repository.name} with branch: #{branch_name}")

    with repo_url <- Repository.build_repository_url(repository),
         {:ok, git_repo} <- Git.Repo.open(repo_url, "coder-#{agent_id}", branch_name) do
      Logger.debug("Successfully cloned repository to: #{git_repo.path}")
      {:ok, git_repo}
    else
      {:error, reason} ->
        Logger.error("Failed to clone repository: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec create_git_index(map()) :: {:ok, map()} | {:error, binary()}
  defp create_git_index(git_repo) do
    Logger.debug("Creating repository index for: #{git_repo.path}")

    case Git.Index.from(git_repo) do
      {:ok, index} ->
        Logger.debug("Successfully created repository index")
        {:ok, index}

      {:error, reason} ->
        Logger.error("Failed to create repository index: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # LLM Chain Execution

  @spec execute_implementation(Agent.t(), map(), map()) :: work_result()
  defp execute_implementation(agent, git_repo, git_index) do
    Logger.debug("Implementing changes")

    tools = prepare_tools(agent)
    messages = prepare_messages(agent, git_repo)
    custom_context = prepare_custom_context(agent, git_repo, git_index)

    SharedLLMChain.create(
      agent: agent,
      max_tokens: 64000,
      temperature: 0.7,
      custom_context: custom_context,
      verbose: false
    )
    |> LLMChain.add_messages(messages)
    |> LLMChain.add_tools(tools)
    |> SharedLLMChain.run_until_finished("finished")
  end

  @spec prepare_tools(Agent.t()) :: [map()]
  defp prepare_tools(agent) do
    finished_tool = SharedLLMChain.create_finished_tool()
    agent_tools = Swarm.Tools.for_agent(agent)

    agent_tools ++ [finished_tool]
  end

  @spec prepare_messages(Agent.t(), map()) :: [Message.t()]
  defp prepare_messages(%Agent{context: instructions, repository: repository}, git_repo) do
    system_message = build_system_message(repository, git_repo)
    user_message = build_user_message(instructions)

    [system_message, user_message]
  end

  @spec build_system_message(Repository.t(), map()) :: Message.t()
  defp build_system_message(repository, git_repo) do
    system_prompt = """
    You are a software developer called Swarm AI implementing changes to a codebase. Examine the files carefully and implement the requested changes according to the instructions.
    Write files and commit changes immediately- do not ask for confirmation.
    You're in a temporary dev environment with a checked out branch where you can make changes and push them to the remote repository.
    Open a pull request once completed. If there are newline file terminators, keep them.

    Repo info #{repository.owner}/#{repository.name}:
    - Branch: #{git_repo.branch}

    """

    Message.new_system!(system_prompt)
  end

  @spec build_user_message(binary()) :: Message.t()
  defp build_user_message(instructions) do
    user_prompt = "I need to implement the following changes: #{inspect(instructions)}"
    Message.new_user!(user_prompt)
  end

  @spec prepare_custom_context(Agent.t(), map(), map()) :: map()
  defp prepare_custom_context(agent, git_repo, git_index) do
    repository = agent.repository
    organization = Swarm.Repo.preload(repository, :organization).organization

    %{
      "git_repo" => git_repo,
      "git_repo_index" => git_index,
      "repository" => repository,
      "organization" => organization,
      "agent" => agent
    }
  end
end