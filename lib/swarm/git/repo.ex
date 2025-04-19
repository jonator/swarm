defmodule Swarm.Git.Repo do
  use TypedStruct
  require Logger

  @base_dir Path.join(System.tmp_dir(), Atom.to_string(__MODULE__))

  typedstruct enforce: true do
    field :url, String.t(), enforce: true
    field :branch, String.t(), enforce: true
    field :path, String.t(), enforce: true
    field :closed, boolean(), default: false
  end

  @doc """
  Opens a git repository and switches to a branch.
  """
  def open(url, slug, branch) do
    path = make_path(url, slug)
    Logger.debug("Opening repository: url=#{url}, slug=#{slug}, branch=#{branch}, path=#{path}")

    with {:ok, _} <- clone_repo(url, path),
         {:ok, _} <- switch_branch(path, branch) do
      {:ok, %__MODULE__{url: url, path: path, branch: branch}}
    else
      {:error, error} ->
        {:error, "Failed to open repository: #{url} #{error}"}
    end
  end

  @doc """
  Closes a git repository and deletes the directory.
  """
  def close(%__MODULE__{url: url, path: path, branch: branch}) do
    Logger.debug("Closing repository: url=#{url}, path=#{path}, branch=#{branch}")

    case File.rm_rf(path) do
      {:ok, _} ->
        {:ok, %__MODULE__{url: url, path: path, branch: branch, closed: true}}

      error ->
        error
    end
  end

  @doc """
  Gets the status of a git repository.
  """
  def status(%__MODULE__{path: path}) do
    Logger.debug("Getting repository status: path=#{path}")

    case System.cmd("git", ["status"], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to get status"}
    end
  end

  @doc """
  Lists all relative file paths in the repository.
  """
  def list_files(%__MODULE__{path: path}) do
    Logger.debug("Listing repository files: path=#{path}")

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
  def open_file(%__MODULE__{path: path}, file) do
    Logger.debug("Opening file: path=#{path}, file=#{file}")
    File.read(Path.join(path, file))
  end

  @doc """
  Writes content to a relative file path in the repository.
  """
  def write_file(%__MODULE__{path: path}, file, content) do
    Logger.debug("Writing file: path=#{path}, file=#{file}")

    case File.write(Path.join(path, file), content) do
      :ok -> {:ok, "File written successfully"}
      error -> {:error, "Failed to write file: #{error}"}
    end
  end

  @doc """
  Renames a file in the repository.
  """
  def rename_file(%__MODULE__{path: path}, old_file, new_file) do
    Logger.debug("Renaming file: path=#{path}, old_file=#{old_file}, new_file=#{new_file}")

    case System.cmd("git", ["mv", "--quiet", old_file, new_file], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to rename file from #{old_file} to #{new_file}"}
    end
  end

  @doc """
  Adds a file to the staging area of the repository.
  """
  def add_file(%__MODULE__{path: path}, file) do
    Logger.debug("Adding file: path=#{path}, file=#{file}")

    case System.cmd("git", ["add", file], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to add file #{file}"}
    end
  end

  @doc """
  Adds all files to the staging area of the repository.
  """
  def add_all_files(%__MODULE__{path: path}) do
    Logger.debug("Adding all files: path=#{path}")

    case System.cmd("git", ["add", "."], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to add all files"}
    end
  end

  @doc """
  Commits the changes to the repository.
  """
  def commit(%__MODULE__{path: path}, message) do
    Logger.debug("Committing changes: path=#{path}, message=#{message}")

    case System.cmd("git", ["commit", "-m", message], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to commit changes with message: #{message}"}
    end
  end

  @doc """
  Pushes the current branch to origin.
  """
  def push_origin(%__MODULE__{path: path, branch: branch}) do
    Logger.debug("Pushing to origin: path=#{path}, branch=#{branch}")

    case System.cmd("git", ["push", "--set-upstream", "origin", branch], cd: path) do
      {output, 0} -> {:ok, output}
      _ -> {:error, "Failed to push to origin"}
    end
  end

  defp clone_repo(url, path) do
    if File.exists?(path) and File.exists?(Path.join(path, ".git")) do
      {:ok, "Already cloned"}
    else
      case System.cmd("git", ["clone", "--filter=blob:none", "--quiet", url, path]) do
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
