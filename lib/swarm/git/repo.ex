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
         :ok <- switch_branch(path, branch) do
      {:ok, %__MODULE__{url: url, path: path, branch: branch}}
    end
  end

  def close(%__MODULE__{url: url, path: path, branch: branch}) do
    File.rm_rf!(path)
    {:ok, %__MODULE__{url: url, path: path, branch: branch, closed: true}}
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

  defp clone_repo(url, path) do
    if File.exists?(path) and File.exists?(Path.join(path, ".git")) do
      :ok
    else
      case System.cmd("git", ["clone", "--quiet", url, path]) do
        {_, 0} -> :ok
        _ -> {:error, "Failed to clone repository: #{url}"}
      end
    end
  end

  defp switch_branch(path, branch) do
    case System.cmd("git", ["switch", "-C", branch, "--quiet"], cd: path) do
      {_, 0} -> :ok
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
