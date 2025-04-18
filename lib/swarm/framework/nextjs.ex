defmodule Swarm.Framework.Nextjs.Package do
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
  use TypedStruct

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
    case Swarm.Git.Repo.list_files(repo) do
      {:ok, files} ->
        # Find next.config.* files
        config_files =
          files
          |> Enum.find(fn file ->
            Enum.any?(@nextjs_indicator, &Regex.match?(&1, file))
          end)

        case config_files do
          nil ->
            {:error, "No Next.js configuration found"}

          config_file ->
            # Get the directory containing the config file
            root_dir = Path.dirname(config_file)

            # Get the package.json file in the same root directory
            package_json_file =
              files
              |> Enum.find(fn file ->
                Path.dirname(file) == root_dir && Regex.match?(@package_json_indicator, file)
              end)

            {:ok, package} = Swarm.Framework.Nextjs.Package.try_new(repo, package_json_file)

            {:ok, new(repo, root_dir, package)}
        end

      {:error, reason} ->
        {:error, "Failed to list files while detecting Next.js: #{reason}"}
    end
  end

  def new(%Swarm.Git.Repo{} = repo, root_dir, package),
    do: %__MODULE__{repo: repo, root_dir: root_dir, package: package}
end
