defmodule Swarm.Git.Index do
  @moduledoc false

  use TypedStruct
  require Logger

  # 1MB chunks
  @chunk_size 1024 * 1024
  # 10MB max file size
  @max_file_size 10 * 1024 * 1024
  @excluded_patterns [
    ~r/\.git/,
    ~r/\.(jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$/i,
    ~r/\.(zip|tar|gz|rar|7z)$/i,
    ~r/\.(exe|dll|so|dylib)$/i,
    ~r/\.(mp4|mov|avi|wmv|flv|mkv)$/i,
    ~r/\.(mp3|wav|ogg|flac)$/i,
    ~r/\.(pdf|doc|docx|xls|xlsx|ppt|pptx)$/i,
    ~r/\.(db|sqlite|sqlite3)$/i,
    ~r/\.(log|lock)$/i,
    ~r/\.(min\.|bundle\.|chunk\.|vendor\.)/i,
    ~r/\.(map|sourcemap)$/i,
    ~r/\.(pyc|pyo|pyd)$/i,
    ~r/\.(class|jar|war)$/i,
    ~r/\.(o|obj|a|lib)$/i,
    ~r/\.(ex|beam)$/i,
    ~r/\.(cache|tmp|temp)$/i,
    ~r/\.(DS_Store|Thumbs\.db)$/i,
    ~r/\.(env|venv|node_modules|dist|build|target|_build|deps)/i,
    ~r/\.(coverage|lcov|gcov|gcda|gcno)$/i,
    ~r/\.(swp|swo|bak|backup)$/i,
    ~r/\.(min\.|bundle\.|chunk\.|vendor\.)/i,
    ~r/\.(map|sourcemap)$/i,
    ~r/\.(pyc|pyo|pyd)$/i,
    ~r/\.(class|jar|war)$/i,
    ~r/\.(o|obj|a|lib)$/i,
    ~r/\.(ex|beam)$/i,
    ~r/\.(cache|tmp|temp)$/i,
    ~r/\.(DS_Store|Thumbs\.db)$/i,
    ~r/\.(env|venv|node_modules|dist|build|target|_build|deps)/i,
    ~r/\.(coverage|lcov|gcov|gcda|gcno)$/i,
    ~r/\.(swp|swo|bak|backup)$/i
  ]

  typedstruct enforce: true do
    field :index, Search.Index.t()
  end

  def from(%Swarm.Git.Repo{} = repo, excluded_patterns \\ []) do
    Logger.debug(
      "Creating index from repository: path=#{repo.path}, excluded_patterns=#{inspect(excluded_patterns)}"
    )

    case Swarm.Git.Repo.list_files(repo) do
      {:ok, file_paths} ->
        # Filter out excluded files
        file_paths = filter_files(file_paths, excluded_patterns)
        Logger.debug("Files to index: count=#{length(file_paths)}")

        # Process files in parallel with a limit on concurrent tasks
        tasks =
          file_paths
          |> Task.async_stream(&process_file(repo, &1), max_concurrency: 10, timeout: 30_000)
          |> Enum.to_list()

        # Collect successful results
        documents =
          tasks
          |> Enum.filter(fn
            {:ok, {:ok, _doc}} -> true
            _ -> false
          end)
          |> Enum.map(fn {:ok, {:ok, doc}} -> doc end)

        Logger.debug("Processed documents: count=#{length(documents)}")

        # Create search index
        case documents do
          [] ->
            Logger.debug("No valid files to index: path=#{repo.path}")
            {:error, "No valid files to index"}

          documents ->
            {:ok, new_index} =
              Search.new(fields: [:content])
              |> Search.add(documents)

            Logger.debug(
              "Index created successfully: path=#{repo.path}, document_count=#{length(documents)}"
            )

            {:ok, %__MODULE__{index: new_index}}
        end

      error ->
        error
    end
  end

  def search(%__MODULE__{index: index}, query) do
    Logger.debug("Searching index: query=#{query}")
    Search.search(index, query)
  end

  # Private functions

  defp filter_files(files, excluded_patterns) do
    files
    |> Enum.reject(fn file ->
      Enum.any?(@excluded_patterns ++ excluded_patterns, &Regex.match?(&1, file))
    end)
  end

  defp process_file(repo, file_path) do
    full_path = Path.join(repo.path, file_path)

    with {:ok, file_info} <- File.stat(full_path),
         true <- file_info.size <= @max_file_size,
         {:ok, content} <- read_file_in_chunks(full_path) do
      {:ok, %{id: file_path, content: content}}
    else
      _ -> {:error, "Failed to process file: #{file_path}"}
    end
  end

  defp read_file_in_chunks(path) do
    case File.open(path, [:read, :binary]) do
      {:ok, file} ->
        try do
          content =
            Stream.unfold(file, fn file ->
              case :file.read(file, @chunk_size) do
                {:ok, data} -> {data, file}
                :eof -> nil
                {:error, reason} -> {:error, reason}
              end
            end)
            |> Enum.join("")

          {:ok, content}
        after
          File.close(file)
        end

      error ->
        error
    end
  end
end
