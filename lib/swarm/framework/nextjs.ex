defmodule Swarm.Framework.Nextjs do
  use TypedStruct

  typedstruct enforce: true do
    field :repo, Swarm.Git.Repo.t()
    field :root_dir, String.t()
  end

  # Search for next.config.* file
  @nextjs_indicator ~r/next\.config\.(js|mjs|cjs|ts)$/

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
            {:ok, new(repo, root_dir)}
        end

      {:error, reason} ->
        {:error, "Failed to list files while detecting Next.js: #{reason}"}
    end
  end

  def new(%Swarm.Git.Repo{} = repo, root_dir \\ "."),
    do: %__MODULE__{repo: repo, root_dir: root_dir}
end
