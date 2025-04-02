defmodule Swarm.GitRepo do
  use TypedStruct

  @base_dir Path.join(System.tmp_dir(), Atom.to_string(__MODULE__))

  typedstruct enforce: true do
    field :origin_url, String.t()
    field :branch, String.t()
    field :path, String.t()
    field :lock, Mutex.Lock.t()
  end

  def open(url, branch) do
    path = make_path(url)

    with :ok <- clone_repo(url, path),
         :ok <- switch_branch(path, branch),
         lock <- Mutex.await(Swarm.Mutex, __MODULE__) do
      {:ok, %__MODULE__{origin_url: url, path: path, branch: branch, lock: lock}}
    end
  end

  def release(%__MODULE__{lock: lock}), do: Mutex.release(Swarm.Mutex, lock)

  @doc """
  Lists all file paths in the repository.
  """
  def list_files(%__MODULE__{path: path}) do
    case System.cmd("git", ["ls-files"], cd: path) do
      {output, 0} ->
        file_list = output |> String.split("\n", trim: true)
        {:ok, file_list}

      {error, _} ->
        {:error, "Failed to list repository files: #{error}"}
    end
  end

  defp clone_repo(url, path) do
    if File.exists?(path) and File.exists?(Path.join(path, ".git")) do
      :ok
    else
      case System.cmd("git", ["clone", url, path]) do
        {_, 0} -> :ok
        _ -> {:error, "Failed to clone repository: #{url}"}
      end
    end
  end

  defp switch_branch(path, branch) do
    IO.inspect(path, label: "SWITCH PATH")
    IO.inspect(branch, label: "SWITCH BRANCH")

    case System.cmd("git", ["switch", "-C", branch], cd: path) do
      {_, 0} -> :ok
      _ -> {:error, "Failed to switch to branch #{branch}"}
    end
  end

  defp make_path(url) do
    path =
      url
      |> String.replace(~r/\.git$/, "")
      |> String.split("/")
      |> Enum.take(-2)
      |> Enum.join("/")

    Path.join(@base_dir, path)
  end
end
