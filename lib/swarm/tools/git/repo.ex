defmodule Swarm.Tools.Git.Repo do
  alias LangChain.Function
  alias LangChain.FunctionParam

  def all_tools(:read),
    do: [status(), list_files(), open_file(), search(), symbolic_analysis()]

  def all_tools(:read_write),
    do:
      all_tools(:read) ++
        [
          add_file(),
          add_all_files(),
          commit(),
          rename_file(),
          write_file(),
          push_origin()
        ]

  def add_file do
    Function.new!(%{
      name: "add_file",
      description: "Adds a file to the staging area of the git repository.",
      parameters: [
        FunctionParam.new!(%{
          name: "file",
          type: :string,
          description: "The relative path of the file to add to the staging area.",
          required: true
        })
      ],
      function: fn %{"file" => file} = _arguments, %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.add_file(git_repo, file) |> handle_repo_response()
      end
    })
  end

  def add_all_files do
    Function.new!(%{
      name: "add_all_files",
      description: "Adds all files to the staging area of the git repository.",
      parameters: [],
      function: fn _arguments, %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.add_all_files(git_repo) |> handle_repo_response()
      end
    })
  end

  def commit do
    Function.new!(%{
      name: "commit",
      description: "Commits the changes to the git repository. Keep it short and concise.",
      parameters: [
        FunctionParam.new!(%{
          name: "message",
          type: :string,
          description: "The commit message.",
          required: true
        })
      ],
      function: fn %{"message" => message} = _arguments, %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.commit(git_repo, message) |> handle_repo_response()
      end
    })
  end

  def push_origin do
    Function.new!(%{
      name: "push_origin",
      description: "Pushes the current branch to origin.",
      parameters: [],
      function: fn _arguments, %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.push_origin(git_repo) |> handle_repo_response()
      end
    })
  end

  def rename_file do
    Function.new!(%{
      name: "rename_file",
      description: "Renames a file in the git repository.",
      parameters: [
        FunctionParam.new!(%{
          name: "old_file",
          type: :string,
          description: "The relative path of the file to be renamed.",
          required: true
        }),
        FunctionParam.new!(%{
          name: "new_file",
          type: :string,
          description: "The new relative path for the file. Keep it short and concise.",
          required: true
        })
      ],
      function: fn %{"old_file" => old_file, "new_file" => new_file} = _arguments,
                   %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.rename_file(git_repo, old_file, new_file) |> handle_repo_response()
      end
    })
  end

  def list_files do
    Function.new!(%{
      name: "list_files",
      description: "Lists all relative file paths in the git repository.",
      parameters: [],
      function: fn _arguments, %{"git_repo" => git_repo} ->
        case Swarm.Git.Repo.list_files(git_repo) do
          {:ok, files} -> Enum.join(files, "\n")
          {:error, msg} -> "Error: #{msg}"
        end
      end
    })
  end

  def open_file do
    Function.new!(%{
      name: "open_file",
      description: "Opens and reads a file from the git repository.",
      parameters: [
        FunctionParam.new!(%{
          name: "file",
          type: :string,
          description: "The relative path of the file to open.",
          required: true
        })
      ],
      function: fn %{"file" => file} = _arguments, %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.open_file(git_repo, file) |> handle_repo_response()
      end
    })
  end

  def write_file do
    Function.new!(%{
      name: "write_file",
      description:
        "Writes content to a file in the git repository. Include line break at the end of the content.",
      parameters: [
        FunctionParam.new!(%{
          name: "file",
          type: :string,
          description: "The relative path of the file to write to.",
          required: true
        }),
        FunctionParam.new!(%{
          name: "content",
          type: :string,
          description: "The content to write to the file.",
          required: true
        })
      ],
      function: fn %{"file" => file, "content" => content} = _arguments,
                   %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.write_file(git_repo, file, content) |> handle_repo_response()
      end
    })
  end

  def status do
    Function.new!(%{
      name: "status",
      description: "Returns the status of the git repository.",
      parameters: [],
      function: fn _arguments, %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.status(git_repo) |> handle_repo_response()
      end
    })
  end

  def search do
    Function.new!(%{
      name: "search",
      description: """
      Search code repositories using ripgrep (rg) with regex patterns. Core usage: `rg [OPTIONS] PATTERN [PATH ...]`.

      Key flags: `-i` (ignore case), `-v` (invert match), `-w` (word boundaries), `-x` (line boundaries), `-F` (literal strings), `-m NUM` (max matches), `-U` (multiline).

      File filtering: `-t TYPE` (file type like py/js/rs), `-T TYPE` (exclude type), `-g GLOB` (glob patterns), `--hidden` (include hidden), `--no-ignore` (skip .gitignore), `-d NUM` (max depth).

      Output control: `-n` (line numbers), `-H`/`-I` (show/hide filename), `--column` (column numbers), `-o` (only matches), `-c` (count), `-l` (files with matches), `--files-without-match`, `--json` (JSON output), `-q` (quiet).

      Context: `-A NUM` (after), `-B NUM` (before), `-C NUM` (around matches).

      Utilities: `--files` (list searchable files), `--type-list` (show file types), `--stats` (search stats), `-r TEXT` (replace display).

      Examples: `rg -t py "def \w+" -n` (Python functions), `rg "TODO" -i -C 2` (TODOs with context), `rg "import" -l -t js` (JS files with imports), `rg "error" --json -c` (error counts in JSON).
      """,
      parameters: [
        FunctionParam.new!(%{
          name: "args",
          type: :array,
          item_type: "string",
          description:
            "Command flags to provide to the base ripgrep command (NOT the base rg command). i.e. ['-t', 'py', '-i', 'def', '\\w+', '-n']",
          required: true
        })
      ],
      function: fn %{"args" => args} = _arguments, %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.search(git_repo, args)
        |> handle_repo_response()
      end
    })
  end

  def symbolic_analysis do
    Function.new!(%{
      name: "symbolic_analysis",
      description: """
      Analyzes codebase symbols and generates a structured report for the given path.

      USAGE: aid [path] [flags]

      COMMON PATTERNS:
      - Basic analysis: aid ./src
      - Include specific files: aid ./src --include "*.ts,*.js"
      - Exclude test files: aid ./src --exclude "*.test.ts,*.spec.js"
      - Format as markdown: aid ./src --format md

      KEY FLAGS:
      --format FORMAT         Output format: text|md|jsonl|json-structured|xml (default: text)
      --include PATTERNS      File patterns to include (e.g., "*.ts,*.js")
      --exclude PATTERNS      File patterns to exclude (e.g., "*.test.ts,*.spec.js")
      --public/--private      Control visibility (0/1, default: public=1)
      --comments              Include comments (0/1)
      --implementation        Include implementation details (0/1)
      --lang LANGUAGE         Force language: auto|python|typescript|javascript|go|rust|java|csharp|kotlin|cpp|php|ruby|swift

      Supported languages: auto|python|typescript|javascript|go|rust|java|csharp|kotlin|cpp|php|ruby|swift

      Example output for a TypeScript file:
      <file path=\"lib/services/users.ts\">
      import 'node:crypto'
      import '@/lib/client/authed'
      type User = { id: number; email: string; username: string; avatar_url: string }
      type GetUserParams = { id?: number }
      export async function getUser(params: GetUserParams)
      </file>
      """,
      parameters: [
        FunctionParam.new!(%{
          name: "args",
          type: :array,
          item_type: "string",
          description:
            "Command flags to provide to the aid command. The path should be the first argument, followed by any flags. Example: ['./src', '--ai-action', 'prompt-for-refactoring-suggestion', '--include', '*.ts,*.js']",
          required: true
        })
      ],
      function: fn %{"args" => args} = _arguments, %{"git_repo" => git_repo} ->
        Swarm.Git.Repo.symbolic_analysis(git_repo, args) |> handle_repo_response()
      end
    })
  end

  defp handle_repo_response({:ok, output}) when is_binary(output) do
    if output == "", do: "OK", else: output
  end

  defp handle_repo_response({:ok, _}), do: "OK"
  defp handle_repo_response({:error, msg}), do: "Error: #{msg}"
end
