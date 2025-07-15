defmodule Swarm.Tools.Shell do
  require Logger

  alias LangChain.Function
  alias LangChain.FunctionParam
  alias Swarm.Git.Repo
  alias Swarm.Services.GitHub
  alias Swarm.Agents

  def all_tools(:read_write) do
    [shell_command()]
  end

  def all_tools(:read) do
    []
  end

  def shell_command do
    Function.new!(%{
      name: "shell_command",
      description: """
      Run a shell command in the repository's working directory.
      You can use git and gh CLIs to interact with the git repository and GitHub API.
      The environment has GH_TOKEN set to a valid GitHub access token for authentication.
      For gh, it will use GH_TOKEN automatically.
      Then you can git push.

      Available commands and tools in the environment:

      File Operations:
      - ls, cat, cp, mv, rm, mkdir, rmdir, chmod, chown
      - find, grep, sed, awk, sort, uniq, head, tail, wc
      - tar, gzip, zip, unzip (compression/archiving)
      - tree (directory structure visualization)
      - file (file type detection)
      - less (file pager)
      - echo (output text to files/stdout)
      - touch (create empty files)

      Development Tools:
      - git (version control)
      - gh (GitHub CLI)
      - make, cmake (build tools)
      - gcc, g++, clang (C/C++ compilers via build-essential)
      - python3, pip (Python development)
      - node, npm (Node.js development)
      - bun (Bun.js runtime)
      - deno (Deno runtime)
      - golang (Go development)
      - ruby (Ruby development)
      - rust (Rust development)
      - sqlite3 (database operations)
      - jq (JSON processing)
      - asdf (version manager for switching versions of nodejs, python, golang, ruby, bun, deno, rust, java)
      - You can change the version of a dependency with asdf, e.g. `asdf global python 3.12.3` or `asdf local nodejs 20.11.1` or `asdf install ruby 3.2.0` to add a new version.

      System Tools:
      - ps, top, kill, killall (process management)
      - df, du (disk usage)
      - id, useradd, passwd (user management)
      - curl, wget (network requests)
      - which, whereis (command location)
      - env, export (environment variables)

      Shell Features:
      - bash, sh (shell execution)
      - Pipes (|), redirection (>, >>), command chaining (&&, ||)
      - Background processes (&)
      - Command substitution $(command)
      - Environment variables and expansions
      - File creation with: echo "content" > file.txt
      - File appending with: echo "content" >> file.txt
      """,
      parameters: [
        FunctionParam.new!(%{
          name: "command",
          type: :string,
          description: "The shell command to run.",
          required: true
        })
      ],
      function: fn %{"command" => command}, %{"agent" => agent, "git_repo" => git_repo} ->
        Repo.run_shell_command(git_repo, command,
          env: [{"GH_TOKEN", git_repo.github_client.client.auth.access_token}]
        )
        |> shell_result(agent, git_repo)
      end
    })
  end

  defp shell_result({:ok, ""}, _agent, _git_repo) do
    "Command executed successfully."
  end

  # Extract PR details if 'gh pr create' was used and returns a PR URL
  defp shell_result({:ok, output}, agent, git_repo) do
    pr_url_regex =
      ~r{https://github\.com/(?<org>[^/]+)/(?<repo>[^/]+)/pull/(?<pull_request_number>\d+)}

    case Regex.run(pr_url_regex, output, capture: :all_names) do
      [org, pull_request_number, repo] ->
        repository = Swarm.Repo.preload(agent, :repository).repository

        if repository.owner == org and repository.name == repo do
          add_pull_request_external_ids(agent, pull_request_number, git_repo, repository)

          output
        end

        output

      _ ->
        output
    end
  end

  defp shell_result({:error, error}, _agent, _git_repo) do
    error
  end

  defp add_pull_request_external_ids(agent, pull_request_number, git_repo, repository) do
    github_client = git_repo.github_client

    case GitHub.pull_request_info(
           github_client,
           repository.owner,
           repository.name,
           pull_request_number
         ) do
      {:ok, pull_request} ->
        external_ids =
          Map.get(agent, :external_ids, %{})
          |> Map.put("github_pull_request_number", pull_request["number"])
          |> Map.put("github_pull_request_id", pull_request["id"])
          |> Map.put("github_pull_request_url", pull_request["html_url"])

        Agents.update_agent(agent, %{external_ids: external_ids})

        Logger.debug("Added pull request external IDs: #{inspect(external_ids)}")

      {:error, error} ->
        Logger.error("Failed to add pull request external IDs: #{inspect(error)}")
    end
  end
end
