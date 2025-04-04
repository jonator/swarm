defmodule Swarm.Instructor.RelevantFiles do
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Fields
  - `files`: An array of file paths that are relevant to the prompt.
  """
  @primary_key false
  embedded_schema do
    field(:files, {:array, :string})
  end

  def get_relevant_files(%Swarm.Git.Repo{} = repo, prompt) do
    {:ok, files} = repo |> Swarm.Git.Repo.list_files()

    files = files |> Enum.join("\n")

    Instructor.chat_completion(
      model: "gpt-4o-mini",
      response_model: __MODULE__,
      messages: [
        %{
          role: "user",
          content: """
          You are a helpful assistant that determines which code repo files are relevant to a given prompt.

          The prompt is:
          #{prompt}

          The file list is:
          #{files}

          """
        }
      ]
    )
  end
end
