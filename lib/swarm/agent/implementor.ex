defmodule Swarm.Agent.Implementor do
  def implement(%Swarm.Git.Repo{} = repo, files, instructions) do
    alias LangChain.Chains.LLMChain
    alias LangChain.Message
    alias LangChain.ChatModels.ChatOpenAI
    alias Swarm.Tool.Repo, as: ToolRepo

    # Set up the tools from Repo module
    tools = ToolRepo.all_tools()

    # Create messages for the LLM
    messages = [
      Message.new_system!("""
      You are a software developer implementing changes to a codebase. Examine the files carefully and implement the requested changes according to the instructions.
      Write files and commit changes immediately- do not ask for confirmation.

      Key files of note: #{files}

      """),
      Message.new_user!("I need to implement the following changes: #{inspect(instructions)}")
    ]

    # Set up the chat model
    chat_model =
      ChatOpenAI.new!(%{
        model: "gpt-4o",
        temperature: 0.7,
        stream: false
      })

    # Run the LLM chain with tools to implement the changes
    {:ok, updated_chain} =
      %{llm: chat_model, custom_context: repo, verbose: true}
      |> LLMChain.new!()
      |> LLMChain.add_messages(messages)
      |> LLMChain.add_tools(tools)
      |> LLMChain.run(mode: :while_needs_response)

    # Return the updated repository
    updated_chain.last_message.content
  end
end
