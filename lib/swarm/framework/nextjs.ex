defmodule Swarm.Framework.Nextjs.Package do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :file_path, String.t(), enforce: true
    field :content, map(), enforce: true
  end

  def try_new(%Swarm.Git.Repo{} = repo, file_path) do
    case Swarm.Git.Repo.open_file(repo, file_path) do
      {:ok, content} ->
        content = Jason.decode!(content)

        {:ok, %__MODULE__{file_path: file_path, content: content}}

      {:error, reason} ->
        {:error, "Failed to read package.json file: #{reason}"}
    end
  end
end

defmodule Swarm.Framework.Nextjs do
  @moduledoc false

  use TypedStruct

  def key, do: "nextjs"

  typedstruct enforce: true do
    field :repo, Swarm.Git.Repo.t(), enforce: true
    field :root_dir, String.t(), enforce: true
    field :package, __MODULE__.Package.t(), enforce: true
    field :is_setup, boolean(), default: false
  end

  # Search for next.config.* file
  @nextjs_indicator ~r/next\.config\.(js|mjs|cjs|ts)$/
  @package_json_indicator ~r/package\.json$/

  def detect(%Swarm.Git.Repo{} = repo) do
    with {:ok, files} <- Swarm.Git.Repo.list_files(repo),
         config_file when not is_nil(config_file) <-
           Enum.find(files, fn file ->
             Enum.any?(@nextjs_indicator, &Regex.match?(&1, file))
           end),
         root_dir = Path.dirname(config_file),
         package_json_file when not is_nil(package_json_file) <-
           Enum.find(files, fn file ->
             Path.dirname(file) == root_dir && Regex.match?(@package_json_indicator, file)
           end),
         {:ok, package} <- Swarm.Framework.Nextjs.Package.try_new(repo, package_json_file) do
      {:ok, new(repo, root_dir, package)}
    else
      {:error, reason} ->
        {:error, "Failed to list files while detecting Next.js: #{reason}"}

      nil ->
        {:error, "No Next.js configuration found"}

      _ ->
        {:error, "Failed to detect Next.js project structure"}
    end
  end

  def detect(filename) do
    Regex.match?(@nextjs_indicator, filename)
  end

  def new(%Swarm.Git.Repo{} = repo, root_dir, package),
    do: %__MODULE__{repo: repo, root_dir: root_dir, package: package}
end
