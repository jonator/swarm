defmodule Swarm.Instructor.SearchTerms do
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Fields
  - `terms`: An array of search terms that are relevant to the prompt.
  - `files`: An array of file paths that are mentioned in the prompt.
  """
  @primary_key false
  embedded_schema do
    field(:terms, {:array, :string})
    field(:files, {:array, :string})
  end

  def get_search_terms(prompt) do
    Instructor.chat_completion(
      model: "gpt-4o-mini",
      response_model: __MODULE__,
      messages: [
        %{
          role: "user",
          content: """
          You are a helpful assistant that determines which search terms for a git repo are relevant to a given prompt.
          Provide all terms that would be useful for finding code that is needed to implement the prompt, but don't go overboard.
          Only return terms of high confidence and relevance to the prompt.

          Also provide any file paths found in the prompt.

          The prompt is:
          #{prompt}
          """
        }
      ]
    )
  end
end
