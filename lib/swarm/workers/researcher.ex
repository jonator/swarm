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
  alias Swarm.Services.GitHub
  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias LangChain.ChatModels.ChatAnthropic
  alias Swarm.Tools.Git.Repo, as: ToolRepo
  alias Swarm.Egress

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
        agent = Swarm.Repo.preload(agent, [:user, :repository])
        {:ok, agent}
    end
  end

  defp conduct_research(%Agent{} = agent) do
    Logger.info("Conducting research for agent #{agent.id}")

    FLAME.call(Swarm.FlamePool, fn ->
      with {:ok, git_repo} <- clone_repository(agent),
           {:ok, plan} <- generate_llm_implementation_plan(agent, git_repo) do
        Logger.info("Research completed for agent #{agent.id}")
        {:ok, %{plan: plan}}
      end
    end)
  end

  defp generate_llm_implementation_plan(agent, git_repo) do
    Logger.debug("Generating implementation plan via LLM for agent #{agent.id}")

    reply_tool =
      LangChain.Function.new!(%{
        name: "reply",
        description:
          "Reply to the user with the final research plan. Always call this tool with your final plan when you are done.",
        parameters: [
          LangChain.FunctionParam.new!(%{
            name: "message",
            type: :string,
            description: "The message to send as the research plan reply.",
            required: true
          })
        ],
        function: fn %{"message" => message}, %{"external_ids" => external_ids} ->
          if Map.get(external_ids, "linear_issue_id") do
            Egress.reply(external_ids, message)
          else
            {:ok, :skipped}
          end
        end
      })

    tools = ToolRepo.readonly_tools() ++ [reply_tool]

    messages = [
      Message.new_system!("""
      You are a software architect analyzing a codebase and generating a detailed implementation plan based on the user's context and the repository contents. Use the available tools to inspect files and gather information as needed.

      When you are finished, call the reply tool with your final implementation plan. Do not output the plan directly; always use the reply tool to send your answer. If the context is incomplete, ask the user for more information.

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

    chat_model =
      ChatAnthropic.new!(%{
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 4096,
        temperature: 0.5,
        stream: false
      })

    case %{
           llm: chat_model,
           custom_context: %{"git_repo" => git_repo, "external_ids" => agent.external_ids},
           verbose: Logger.level() == :debug
         }
         |> LLMChain.new!()
         |> LLMChain.add_messages(messages)
         |> LLMChain.add_tools(tools)
         |> LLMChain.run_until_tool_used("reply") do
      {:ok, updated_chain, _messages} ->
        {:ok, updated_chain.last_message.content}

      error ->
        Logger.error("LLM plan generation failed: #{inspect(error)}")
        {:error, "LLM plan generation failed: #{inspect(error)}"}
    end
  end

  defp clone_repository(%Agent{user: user, repository: repository, id: agent_id}) do
    Logger.debug("Cloning repository: #{repository.owner}/#{repository.name}")

    # Get repository information from GitHub API
    # Note: In the future when organizations are supported, we will need to
    # get the repository using the organization and not the user
    with {:ok, repo_info} <- GitHub.repository_info(user, repository.owner, repository.name),
         default_branch <- Map.get(repo_info, "default_branch", "main"),
         repo_url <- Repository.build_repository_url(repository),
         # Clone using the default branch
         {:ok, git_repo} <- Git.Repo.open(repo_url, "research-#{agent_id}", default_branch) do
      Logger.debug("Successfully cloned repository to: #{git_repo.path}")
      {:ok, git_repo}
    end
  end
end
