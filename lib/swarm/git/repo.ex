defmodule Swarm.Git.Repo do
  use TypedStruct
  require Logger

  alias Swarm.Agents.Agent
  alias Swarm.Services.GitHub

  @base_dir Path.join(System.tmp_dir(), Atom.to_string(__MODULE__))

  typedstruct enforce: true do
    field :url, String.t(), enforce: true
    field :branch, String.t(), enforce: true
    field :base_branch, String.t(), enforce: true
    field :path, String.t(), enforce: true
    field :linux_user, String.t(), enforce: true
    field :github_client, GitHub.t(), enforce: true
    field :closed, boolean(), default: false
  end

  @doc """
  Opens a git repository using an Agent struct.
  Creates a Linux user, gets GitHub installation token, and clones the repository.
  """
  def open(%Agent{id: agent_id, type: type, repository: repository}, branch) do
    organization = Swarm.Repo.preload(repository, :organization).organization
    slug = "#{type}-#{agent_id}-#{repository.name}"

    Logger.debug(
      "Opening repository for agent: #{agent_id}, repo: #{repository.owner}/#{repository.name}"
    )

    with {:ok, github_client} <- GitHub.new(organization),
         auth_url <-
           "https://x-access-token:#{github_client.client.auth.access_token}@github.com/#{repository.owner}/#{repository.name}.git",
         path <- make_path(auth_url, slug),
         {:ok, linux_user} <- ensure_linux_user(organization),
         {:ok, _} <- create_repo_directory(auth_url, path, linux_user),
         {:ok, default_branch} <- get_default_branch(path, linux_user),
         {:ok, _} <- switch_branch(path, branch, linux_user) do
      {:ok,
       %__MODULE__{
         url: auth_url,
         path: path,
         branch: branch,
         base_branch: default_branch,
         linux_user: linux_user,
         github_client: github_client
       }}
    else
      {:error, error} ->
        Logger.error("Failed to open repository for agent #{agent_id}: #{error}")
        {:error, "Failed to open repository: #{error}"}

      error ->
        Logger.error(
          "Unexpected failure to open repository for agent #{agent_id}: #{inspect(error)}"
        )

        {:error, "Failed to open repository: #{inspect(error)}"}
    end
  end

  def list_files(%__MODULE__{path: path, linux_user: linux_user}) do
    case ucmd(linux_user, "git", ["ls-files"], cd: path) do
      {output, 0} -> {:ok, output}
      {error, _} -> {:error, "Failed to list files: #{error}"}
    end
  end

  def open_file(%__MODULE__{path: path, linux_user: linux_user}, file) do
    case ucmd(linux_user, "cat", [file], cd: path) do
      {output, 0} -> {:ok, output}
      {error, _} -> {:error, "Failed to open file: #{error}"}
    end
  end

  @doc """
  Runs a shell command in the repository's working directory as the linux user.
  """
  def run_shell_command(%__MODULE__{path: path, linux_user: linux_user}, command, opts \\ []) do
    env = Keyword.get(opts, :env, [])
    timeout = Keyword.get(opts, :timeout, 20_000)

    Logger.debug("Running shell command as user #{linux_user}: #{command}")

    # Build environment variable prefix for the command
    # The issue is that when using sudo -u <user> to run commands as a different Linux user, environment variables don't get passed through to the target user's shell session. The sudo command resets the environment for security reasons.
    # This is ideal as the swarm app has full control over the environment variables.
    # And doesn't have to worry about cleaning up any Swarm app or system environment variables.
    env_prefix =
      env
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join(" ")

    # Prepend environment variables to the command if any exist
    full_command =
      if env_prefix != "" do
        "#{env_prefix} #{command}"
      else
        command
      end

    Logger.debug("Full command with environment: #{full_command}")

    # Use Task to run System.cmd with timeout support
    task =
      Task.async(fn ->
        System.cmd(
          "sudo",
          ["-u", linux_user, "sh", "-c", full_command],
          cd: path,
          stderr_to_stdout: true
        )
      end)

    try do
      case Task.await(task, timeout) do
        {output, 0} ->
          {:ok, output}

        {output, exit_code} ->
          {:error, "Command failed with code #{exit_code}: #{output}"}
      end
    catch
      :exit, {:timeout, _} ->
        Task.shutdown(task, :brutal_kill)
        {:error, "Command timed out after #{timeout}ms"}
    end
  end

  defp switch_branch(path, branch, linux_user) do
    case ucmd(linux_user, "git", ["switch", "-C", branch], cd: path) do
      {output, 0} -> {:ok, output}
      {error, _} -> {:error, "Failed to switch to branch #{branch}: #{error}"}
    end
  end

  defp get_default_branch(path, linux_user) do
    case ucmd(linux_user, "git", ["symbolic-ref", "refs/remotes/origin/HEAD"], cd: path) do
      {output, 0} ->
        # Output format: "refs/remotes/origin/main"
        default_branch =
          output
          |> String.trim()
          |> String.split("/")
          |> List.last()

        {:ok, default_branch}

      {_error, _} ->
        # Fall back to checking common default branches
        case ucmd(linux_user, "git", ["branch", "-r"], cd: path) do
          {output, 0} ->
            cond do
              String.contains?(output, "origin/main") -> {:ok, "main"}
              String.contains?(output, "origin/master") -> {:ok, "master"}
              # Default fallback
              true -> {:ok, "main"}
            end

          {error2, _} ->
            # Final fallback
            {:error, "Failed to get default branch: #{error2}"}
        end
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

  # Helper functions for Agent-based repo opening

  defp ensure_linux_user(organization) do
    username = "swarm-#{organization.name}"

    case System.cmd("id", [username], stderr_to_stdout: true) do
      {_, 0} ->
        Logger.debug("Linux user #{username} already exists")
        {:ok, username}

      {_, _} ->
        Logger.debug("Creating Linux user #{username}")

        case System.cmd("sudo", ["useradd", "-G", "swarm-agents", "-m", username],
               stderr_to_stdout: true
             ) do
          {_, 0} ->
            Logger.debug("Successfully created Linux user #{username}")
            {:ok, username}

          {error, _} ->
            Logger.error("Failed to create Linux user #{username}: #{error}")
            {:error, "Failed to create Linux user: #{error}"}
        end
    end
  end

  # Helper function to run git commands as a specific linux user
  defp ucmd(linux_user, command, args, opts \\ []) do
    System.cmd(
      "sudo",
      ["-u", linux_user] ++ [command] ++ args,
      Keyword.merge([stderr_to_stdout: true], opts)
    )
  end

  defp create_repo_directory(auth_url, path, linux_user) do
    if File.exists?(path) and File.exists?(Path.join(path, ".git")) do
      Logger.warning("Repository already exists at #{path}, deleting and re-cloning")

      case ucmd(linux_user, "rm", ["-rf", path]) do
        {_, 0} ->
          Logger.debug("Successfully deleted existing repository at #{path}")
          clone_repository(auth_url, path, linux_user)

        {error, _} ->
          Logger.error("Failed to delete existing repository at #{path}: #{error}")
          {:error, "Failed to delete existing repository: #{error}"}
      end
    else
      Logger.debug("Cloning repository as user #{linux_user}")
      clone_repository(auth_url, path, linux_user)
    end
  end

  defp clone_repository(auth_url, path, linux_user) do
    case ucmd(linux_user, "git", [
           "clone",
           "--filter=blob:none",
           "--quiet",
           auth_url,
           path
         ]) do
      {output, 0} ->
        # Configure git user for Swarm GitHub App
        configure_git_user(path, linux_user)
        {:ok, output}

      {error, _} ->
        {:error, "Failed to clone repository: #{auth_url}: #{error}"}
    end
  end

  defp configure_git_user(path, linux_user) do
    github_app_id = Application.get_env(:swarm, :github_client_id)

    # Add repository to Git safe directories to prevent dubious ownership warnings
    ucmd(linux_user, "git", ["config", "--global", "--add", "safe.directory", path])

    # Set git user name as swarm[bot]
    ucmd(linux_user, "git", ["config", "user.name", "swarm[bot]"], cd: path)

    # Set git user email as {app_id}+swarm[bot]@users.noreply.github.com
    email = "#{github_app_id}+swarm[bot]@users.noreply.github.com"
    ucmd(linux_user, "git", ["config", "user.email", email], cd: path)

    Logger.debug("Configured git user for Swarm GitHub App: swarm[bot] <#{email}>")
  end
end
