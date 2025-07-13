defmodule Swarm.Instructor.AgentName do
  @moduledoc false
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Fields
  - `agent_name`: A string representing a descriptive name for an AI agent based on the provided instructions or context.
  """
  @primary_key false
  embedded_schema do
    field(:agent_name, :string)
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
            You are a helpful assistant that generates a descriptive, human-readable name for an AI agent based on the following instructions or context.

            The name should be concise, clear, and reflect the purpose or task described. Avoid generic names; be specific to the context.
            They should be similar to names you'd write for a pull request title.
            Avoid leaking low level identifiers, these are for human consumption only.

            Examples:
            Improve Spacing
            Add Tests
            Research Authentication Implementation

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
