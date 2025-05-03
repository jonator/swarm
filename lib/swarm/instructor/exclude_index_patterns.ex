defmodule Swarm.Instructor.ExcludeIndexPatterns do
  @moduledoc false
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Fields
  - `patterns`: An array of regex pattern strings that should be excluded from indexing.
  """
  @primary_key false
  embedded_schema do
    field(:patterns, {:array, :string})
  end

  def get_exclude_patterns(prompt) do
    Instructor.chat_completion(
      [
        model: "gpt-4o-mini",
        response_model: __MODULE__,
        messages: [
          %{
            role: "user",
            content: """
            You are a helpful assistant that determines which file patterns should be EXCLUDED from indexing based on a given prompt.

            The prompt is:
            #{prompt}

            Based on this prompt, provide regex patterns for files that should be EXCLUDED from indexing for search.
            Not files that should be included for implementation and indexing.
            These should be files that are irrelevant to the task or would add noise to the search results or needlessly increase the index size.
            Return patterns as strings that can be compiled into Elixir regular expressions.
            """
          }
        ]
      ],
      adapter: Instructor.Adapters.OpenAI,
      api_key: Application.fetch_env!(:instructor, :openai)[:api_key]
    )
  end
end
