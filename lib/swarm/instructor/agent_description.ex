defmodule Swarm.Instructor.AgentDescription do
  @moduledoc false
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Fields
  - `agent_description`: A string representing a descriptive description for an AI agent based on the provided instructions or context.
  """
  @primary_key false
  embedded_schema do
    field(:agent_description, :string)
  end

  def generate(instructions) do
    Instructor.chat_completion(
      [
        model: "gpt-4o-mini",
        response_model: __MODULE__,
        messages: [
          %{
            role: "user",
            content: """
            You are a helpful assistant that generates a descriptive, human-readable description of the task an AI agent was assigned.

            The description should be concise, clear, and reflect the purpose or task described. Avoid generic descriptions; be specific to the context.
            They should be similar to descriptions you'd write for a pull request or task summary.
            Avoid leaking low level identifiers, these are for human consumption only.

            Examples:
            Improve spacing and layout of components
            Add comprehensive test coverage
            Research authentication implementation patterns

            Instructions/context:
            #{instructions}
            """
          }
        ]
      ],
      adapter: Instructor.Adapters.OpenAI,
      api_key: Application.fetch_env!(:instructor, :openai)[:api_key],
      http_options: [retry: :transient]
    )
  end
end
