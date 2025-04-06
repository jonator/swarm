defmodule Swarm.Agent.Planner do
  def generate_plan(%Swarm.Git.Repo{} = repo, instructions) do
    alias LangChain.Chains.LLMChain
    alias LangChain.Message
    alias LangChain.ChatModels.ChatAnthropic
    alias Swarm.Tool.GitRepo, as: ToolRepo

    # Set up the tools from Repo module
    tools = ToolRepo.all_tools()

    # Create messages for the LLM
    messages = [
      Message.new_system!("""
      You are a software architect creating implementation plans based on instructions and relevant files.

      Include the following sections in your plan:

      ## Application Context
      ## Task
      ### Guidelines
      -- Key files
      -- Key functions or code blocks
      ### Constraints

      Examine the files carefully and create a detailed step-by-step implementation plan.
      """),
      Message.new_user!("I need to create an implementation plan for: #{instructions}")
    ]

    # Set up the chat model
    chat_model =
      ChatAnthropic.new!(%{
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 4096,
        temperature: 0.5,
        stream: false
      })

    # Run the LLM chain with tools to generate the plan
    {:ok, updated_chain} =
      %{llm: chat_model, custom_context: %{"repo" => repo}, verbose: true}
      |> LLMChain.new!()
      |> LLMChain.add_messages(messages)
      |> LLMChain.add_tools(tools)
      |> LLMChain.run(mode: :while_needs_response)

    # Return the implementation plan
    {:ok, %{prompt: [updated_chain.last_message.content]}}
  end
end
