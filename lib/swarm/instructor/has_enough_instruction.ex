defmodule Swarm.Instructor.HasEnoughInstruction do
  @moduledoc false
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Fields
  - `has_enough`: A boolean indicating whether the provided instruction has enough detail to proceed.
  - `reason`: A string explaining why the instruction has enough detail or not.
  """
  @primary_key false
  embedded_schema do
    field(:has_enough, :boolean)
    field(:reason, :string)
  end

  def check(instruction) do
    implementation_keywords = [
      "implementation",
      "implement",
      "steps",
      "todo",
      "file",
      "function",
      "method",
      "class",
      "component",
      "endpoint",
      "api",
      "database"
    ]

    Instructor.chat_completion(
      [
        model: "gpt-4o-mini",
        response_model: __MODULE__,
        messages: [
          %{
            role: "user",
            content: """
            You are a helpful assistant that determines whether a task instruction has enough detail to proceed with implementation in code.

            The instruction is:
            #{instruction}

            Evaluate if this instruction provides enough context and specificity to begin implementation.
            Return true if the instruction is clear and detailed enough, or false if it's too vague or lacks critical information.
            Look for specific files, functions, and code blocks to implement.

            Implementation Keywords:
            #{Enum.join(implementation_keywords, ", ")}
            """
          }
        ]
      ],
      adapter: Instructor.Adapters.OpenAI,
      api_key: Application.fetch_env!(:instructor, :openai)[:api_key]
    )
  end
end
