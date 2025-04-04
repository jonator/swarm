defmodule Swarm.Git.Index do
  use TypedStruct

  typedstruct enforce: true do
    field :index, Search.Index.t()
  end

  def from(%Swarm.Git.Repo{} = repo) do
    with {:ok, file_paths} <- Swarm.Git.Repo.list_files(repo) do
      documents =
        Enum.reduce_while(file_paths, [], fn file_path, acc ->
          full_path = Path.join(repo.path, file_path)

          case File.read(full_path) do
            {:ok, content} ->
              document = %{id: file_path, content: content}
              {:cont, [document | acc]}

            {:error, error} ->
              {:halt, {:error, error}}
          end
        end)

      case documents do
        {:error, error} ->
          {:error, error}

        documents when is_list(documents) ->
          {:ok, new_index} =
            Search.new(fields: [:content]) |> Search.add(Enum.reverse(documents))

          {:ok, %__MODULE__{index: new_index}}
      end
    else
      error -> error
    end
  end

  def search(%__MODULE__{index: index}, query), do: Search.search(index, query)
end
