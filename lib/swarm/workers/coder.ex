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
  alias Swarm.Agents.LLMChain, as: SharedLLMChain
  alias Swarm.Git
  alias Swarm.Instructor
  alias Swarm.Repositories.Repository
  alias Swarm.Services.Linear
  alias LangChain.Chains.LLMChain
  alias LangChain.Message

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

  defp implement_changes_in_repository(%Agent{context: context, repository: repository} = agent) do
    with {:ok, branch_name} <- get_branch_name(agent),
         {:ok, git_repo} <- clone_repository(agent, branch_name),
         {:ok, index} <- create_repository_index(git_repo),
         {:ok, implementation_result} <-
           implement_changes(agent, git_repo, index, repository, context) do
      Logger.info("Code implementation completed for agent #{agent.id}")
      {:ok, %{branch: branch_name, changes: implementation_result}}
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
      {:ok, %{"issue" => %{"branchName" => branch_name}}} ->
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

  defp clone_repository(%Agent{repository: repository, id: agent_id}, branch_name) do
    Logger.debug(
      "Cloning repository: #{repository.owner}/#{repository.name} with branch: #{branch_name}"
    )

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

  defp create_repository_index(repo) do
    Logger.debug("Creating repository index for: #{repo.path}")

    case Git.Index.from(repo) do
      {:ok, index} ->
        Logger.debug("Successfully created repository index")
        {:ok, index}

      {:error, reason} ->
        Logger.error("Failed to create repository index: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp implement_changes(agent, git_repo, git_repo_index, repository, instructions) do
    Logger.debug("Implementing changes")

    # Note: finished tool is used so this agent can handle creating pull requests as needed in response to issues or code reviews
    finished_tool = SharedLLMChain.create_finished_tool()

    # Tool context is passed via custom_context in the LLMChain
    tools = Swarm.Tools.for_agent(agent) ++ [finished_tool]

    messages = [
      Message.new_system!("""
      You are a software developer called Swarm AI implementing changes to a codebase. Examine the files carefully and implement the requested changes according to the instructions.
      Write files and commit changes immediately- do not ask for confirmation.
      You're in a temporary dev environment with a checked out branch where you can make changes and push them to the remote repository.
      Open a pull request once completed. If there are newline file terminators, keep them.

      Repo info #{repository.owner}/#{repository.name}:
      - Branch: #{git_repo.branch}

      """),
      Message.new_user!("I need to implement the following changes: #{inspect(instructions)}")
    ]

    organization = Swarm.Repo.preload(repository, :organization).organization

    # Create LLM chain with shared logic
    SharedLLMChain.create(
      agent: agent,
      max_tokens: 64000,
      temperature: 0.7,
      custom_context: %{
        "git_repo" => git_repo,
        "git_repo_index" => git_repo_index,
        "repository" => repository,
        "organization" => organization,
        "external_ids" => agent.external_ids
      },
      verbose: false
      #  verbose: Logger.level() == :debug
    )
    |> LLMChain.add_messages(messages)
    |> LLMChain.add_tools(tools)
    |> SharedLLMChain.run_until_finished("finished")
  end
end
