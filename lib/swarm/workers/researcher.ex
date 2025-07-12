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
  alias Swarm.Agents.LLMChain, as: SharedLLMChain

  alias LangChain.Chains.LLMChain
  alias LangChain.Message

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
          %Agent{} = fresh_agent -> Agents.mark_agent_failed(fresh_agent)
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
        agent = Swarm.Repo.preload(agent, [:user, repository: :organization])
        {:ok, agent}
    end
  end

  defp conduct_research(%Agent{} = agent) do
    Logger.info("Conducting research for agent #{agent.id}")

    FLAME.call(Swarm.FlamePool, fn ->
      with {:ok, git_repo} <- clone_repository(agent),
           {:ok, plan} <- generate_research(agent, git_repo) do
        Logger.info("Research completed for agent #{agent.id}")
        {:ok, %{plan: plan}}
      end
    end)
  end

  defp generate_research(agent, git_repo) do
    Logger.debug("Generating implementation plan via LLM for agent #{agent.id}")

    finished_tool = SharedLLMChain.create_finished_tool("Indicates that the research is complete")

    tools =
      Swarm.Tools.for_agent(agent, :read_write) ++ [finished_tool]

    messages = [
      Message.new_system!("""
      You are a software architect analyzing a codebase and generating a detailed implementation plan based on the user's context and the repository contents. Use the available tools to inspect files and gather information as needed.

      When you are finished, reply or update a prior plan and call the finished tool If the context is incomplete, ask the user for more information.

      Your plan should:
      - Summarize the application context and requirements
      - Identify key files, directories, and technologies
      - Provide a step-by-step implementation plan
      - Note any technical constraints or considerations
      - Be actionable for a coding agent to follow
      """),
      Message.new_user!("""
      Please analyze the repository and generate an implementation plan for the following context:
      #{agent.context}
      """)
    ]

    # Create LLM chain with shared logic
    SharedLLMChain.create(
      agent: agent,
      custom_context: %{
        "git_repo" => git_repo,
        "repository" => agent.repository,
        "agent" => agent
      }
    )
    |> LLMChain.add_messages(messages)
    |> LLMChain.add_tools(tools)
    |> SharedLLMChain.run_until_finished()
  end

  defp clone_repository(%Agent{repository: repository, id: agent_id} = agent) do
    Logger.debug(
      "Cloning repository for agent #{agent_id}: #{repository.owner}/#{repository.name}"
    )

    # Organization should already be preloaded before entering FLAME worker
    organization = agent.repository.organization

    with {:ok, repo_info} <-
           Swarm.Services.GitHub.repository_info(organization, repository.owner, repository.name),
         default_branch <- Map.get(repo_info, "default_branch", "main"),
         {:ok, git_repo} <- Swarm.Git.Repo.open(agent, default_branch) do
      Logger.debug("Successfully cloned repository for agent #{agent_id} to: #{git_repo.path}")
      {:ok, git_repo}
    else
      {:error, reason} ->
        Logger.error("Failed to clone repository for agent #{agent_id}: #{reason}")
        {:error, reason}
    end
  end
end
