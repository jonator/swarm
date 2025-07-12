defmodule Swarm.Tools.Shell do
  alias LangChain.Function
  alias LangChain.FunctionParam
  alias Swarm.Git.Repo

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
      - gcc, g++, clang (compilers via build-essential)
      - python3, pip (Python development)
      - node, npm (Node.js development)
      - sqlite3 (database operations)
      - jq (JSON processing)

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
      function: fn %{"command" => command}, %{"git_repo" => git_repo} ->
        Repo.run_shell_command(git_repo, command,
          env: [{"GH_TOKEN", git_repo.github_client.client.auth.access_token}]
        )
      end
    })
  end
end
