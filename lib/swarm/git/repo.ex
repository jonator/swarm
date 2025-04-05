defmodule Swarm.Git.Repo do
  use TypedStruct

  @base_dir Path.join(System.tmp_dir(), Atom.to_string(__MODULE__))

  typedstruct enforce: true do
    field :url, String.t()
    field :branch, String.t()
    field :path, String.t()
    field :closed, boolean(), default: false
  end

  def open(url, slug, branch) do
    path = make_path(url, slug)

    with :ok <- clone_repo(url, path),
         {:ok, _} <- switch_branch(path, branch) do
      {:ok, %__MODULE__{url: url, path: path, branch: branch}}
    end
  end

  def close(%__MODULE__{url: url, path: path, branch: branch}) do
    case File.rm_rf(path) do
      {:ok, _} ->
        {:ok, %__MODULE__{url: url, path: path, branch: branch, closed: true}}

      error ->
        error
    end
  end

  @doc """
  Lists all relative file paths in the repository.
  """
  def list_files(%__MODULE__{path: path}) do
    case System.cmd("git", ["ls-files"], cd: path) do
      {output, 0} ->
        file_list = String.split(output, "\n", trim: true)
        {:ok, file_list}

      {error, _} ->
        {:error, "Failed to list repository files: #{error}"}
    end
  end

  @doc """
  Opens a relative file path in the repository.
  """
  def open_file(%__MODULE__{path: path}, file), do: File.read(Path.join(path, file))

  @doc """
  Writes content to a relative file path in the repository.
  """
  def write_file(%__MODULE__{path: path}, file, content),
    do: File.write(Path.join(path, file), content)

  @doc """
  Renames a file in the repository.
  """
  def rename_file(%__MODULE__{path: path}, old_file, new_file) do
    case System.cmd("git", ["mv", "--quiet", old_file, new_file], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to rename file from #{old_file} to #{new_file}"}
    end
  end

  @doc """
  Adds a file to the staging area of the repository.
  """
  def add_file(%__MODULE__{path: path}, file) do
    case System.cmd("git", ["add", file], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to add file #{file}"}
    end
  end

  @doc """
  Adds all files to the staging area of the repository.
  """
  def add_all_files(%__MODULE__{path: path}) do
    case System.cmd("git", ["add", "."], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to add all files"}
    end
  end

  @doc """
  Commits the changes to the repository.
  """
  def commit(%__MODULE__{path: path}, message) do
    case System.cmd("git", ["commit", "-m", message], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to commit changes with message: #{message}"}
    end
  end

  defp clone_repo(url, path) do
    if File.exists?(path) and File.exists?(Path.join(path, ".git")) do
      :ok
    else
      case System.cmd("git", ["clone", url, path]) do
        {output, 0} -> {:ok, output}
        _ -> {:error, "Failed to clone repository: #{url}"}
      end
    end
  end

  defp switch_branch(path, branch) do
    case System.cmd("git", ["switch", "-C", branch], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to switch to branch #{branch}"}
    end
  end

  defp make_path(url, slug) do
    path =
      url
      |> String.replace(~r/\.git$/, "")
      |> String.split("/")
      |> Enum.take(-2)
      |> Enum.join("/")

    Path.join([@base_dir, slug, path])
  end
end
