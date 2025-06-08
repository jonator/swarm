defmodule Swarm.Instructor.AgentType do
  @moduledoc false
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Fields
  - `agent_type`: An enum indicating the type of agent that should handle this task (:researcher, :coder, :code_reviewer).
  - `reason`: A string explaining why this agent type was selected for the given instruction.
  """
  @primary_key false
  embedded_schema do
    field(:agent_type, Ecto.Enum, values: [:researcher, :coder, :code_reviewer])
    field(:reason, :string)
  end

  def determine(instruction) do
    Instructor.chat_completion(
      [
        model: "gpt-4o-mini",
        response_model: __MODULE__,
        adapter: Instructor.Adapters.OpenAI,
        api_key: Application.fetch_env!(:instructor, :openai)[:api_key],
        messages: [
          %{
            role: "user",
            content: """
            You are a helpful assistant that determines what type of AI agent should handle a given task instruction.

            The instruction is:
            #{instruction}

            Based on the instruction, determine which type of agent should handle this task:

            - **researcher**: For tasks that require analyzing code, understanding requirements, gathering information, or providing insights about codebases. Use when the task involves investigation, documentation review, or initial analysis.

            - **coder**: For tasks that involve implementing features, writing code, fixing bugs, creating new functionality, or making specific code changes. Use when the task requires actual coding work.

            - **code_reviewer**: For tasks that involve reviewing pull requests, analyzing existing code quality, providing feedback on implementations, or evaluating code changes. Use when the task involves assessment or review of existing code.

            Return the appropriate agent_type and provide a clear reason for your selection.
            """
          }
        ]
      ]
    )
  end
end
