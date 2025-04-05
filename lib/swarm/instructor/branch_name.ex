defmodule Swarm.Instructor.BranchName do
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Fields
  - `branch_name`: A string representing a git branch name derived from the instructions.
  """
  @primary_key false
  embedded_schema do
    field(:branch_name, :string)
  end

  def generate_branch_name(instructions) do
    Instructor.chat_completion(
      model: "gpt-4o-mini",
      response_model: __MODULE__,
      messages: [
        %{
          role: "user",
          content: """
          You are a helpful assistant that generates appropriate git branch names based on instructions.

          Create a concise, kebab-case branch name that summarizes the following instructions:
          #{instructions}

          The branch name should be descriptive but not too long, and should follow git branch naming conventions.
          """
        }
      ]
    )
  end
end
