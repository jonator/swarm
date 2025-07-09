defmodule Swarm.Tools.Git.Repo do
  @moduledoc """
  Git repository tools for LLM agents.

  This module provides tools for interacting with Git repositories,
  including file operations, staging, committing, and pushing changes.
  All tools are designed to work within the context of an LLM chain
  with access to a git repository through the custom context.
  """

  alias LangChain.Function
  alias LangChain.FunctionParam

  @type tool_mode :: :read | :read_write

  # Tool Collections

  @doc """
  Returns all available tools based on the specified mode.

  ## Parameters
    - mode: `:read` for read-only operations, `:read_write` for all operations

  ## Returns
    - List of LangChain.Function structs
  """
  @spec all_tools(tool_mode()) :: [Function.t()]
  def all_tools(:read), do: read_only_tools()

  def all_tools(_mode), do: read_write_tools()

  @spec read_only_tools() :: [Function.t()]
  defp read_only_tools do
    [
      list_files(),
      open_file(),
      status()
    ]
  end

  @spec read_write_tools() :: [Function.t()]
  defp read_write_tools do
    [
      # File operations
      list_files(),
      open_file(),
      write_file(),
      rename_file(),
      
      # Git operations
      status(),
      add_file(),
      add_all_files(),
      commit(),
      push_origin()
    ]
  end

  # File Operations

  @doc """
  Creates a tool for listing all files in the repository.
  """
  @spec list_files() :: Function.t()
  def list_files do
    Function.new!(%{
      name: "list_files",
      description: "Lists all relative file paths in the git repository.",
      parameters: [],
      function: fn _arguments, %{"git_repo" => git_repo} ->
        execute_git_operation(fn -> Swarm.Git.Repo.list_files(git_repo) end)
      end
    })
  end

  @doc """
  Creates a tool for reading file contents.
  """
  @spec open_file() :: Function.t()
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
      function: fn %{"file" => file}, %{"git_repo" => git_repo} ->
        execute_git_operation(fn -> Swarm.Git.Repo.open_file(git_repo, file) end)
      end
    })
  end

  @doc """
  Creates a tool for writing content to files.
  """
  @spec write_file() :: Function.t()
  def write_file do
    Function.new!(%{
      name: "write_file",
      description: "Writes content to a file in the git repository. Include line break at the end of the content.",
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
      function: fn %{"file" => file, "content" => content}, %{"git_repo" => git_repo} ->
        execute_git_operation(fn -> Swarm.Git.Repo.write_file(git_repo, file, content) end)
      end
    })
  end

  @doc """
  Creates a tool for renaming files.
  """
  @spec rename_file() :: Function.t()
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
      function: fn %{"old_file" => old_file, "new_file" => new_file}, %{"git_repo" => git_repo} ->
        execute_git_operation(fn -> Swarm.Git.Repo.rename_file(git_repo, old_file, new_file) end)
      end
    })
  end

  # Git Operations

  @doc """
  Creates a tool for checking repository status.
  """
  @spec status() :: Function.t()
  def status do
    Function.new!(%{
      name: "status",
      description: "Returns the status of the git repository.",
      parameters: [],
      function: fn _arguments, %{"git_repo" => git_repo} ->
        execute_git_operation(fn -> Swarm.Git.Repo.status(git_repo) end)
      end
    })
  end

  @doc """
  Creates a tool for staging individual files.
  """
  @spec add_file() :: Function.t()
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
      function: fn %{"file" => file}, %{"git_repo" => git_repo} ->
        execute_git_operation(fn -> Swarm.Git.Repo.add_file(git_repo, file) end)
      end
    })
  end

  @doc """
  Creates a tool for staging all files.
  """
  @spec add_all_files() :: Function.t()
  def add_all_files do
    Function.new!(%{
      name: "add_all_files",
      description: "Adds all files to the staging area of the git repository.",
      parameters: [],
      function: fn _arguments, %{"git_repo" => git_repo} ->
        execute_git_operation(fn -> Swarm.Git.Repo.add_all_files(git_repo) end)
      end
    })
  end

  @doc """
  Creates a tool for committing changes.
  """
  @spec commit() :: Function.t()
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
      function: fn %{"message" => message}, %{"git_repo" => git_repo} ->
        execute_git_operation(fn -> Swarm.Git.Repo.commit(git_repo, message) end)
      end
    })
  end

  @doc """
  Creates a tool for pushing changes to origin.
  """
  @spec push_origin() :: Function.t()
  def push_origin do
    Function.new!(%{
      name: "push_origin",
      description: "Pushes the current branch to origin.",
      parameters: [],
      function: fn _arguments, %{"git_repo" => git_repo} ->
        execute_git_operation(fn -> Swarm.Git.Repo.push_origin(git_repo) end)
      end
    })
  end

  # Helper Functions

  @doc """
  Executes a git operation and formats the response appropriately.
  
  Handles both successful operations and errors, providing consistent
  output formatting for the LLM chain.
  """
  @spec execute_git_operation(function()) :: binary()
  defp execute_git_operation(operation) do
    case operation.() do
      {:ok, files} when is_list(files) ->
        format_file_list(files)

      {:ok, output} when is_binary(output) ->
        format_text_output(output)

      {:ok, _} ->
        "OK"

      {:error, message} ->
        format_error_message(message)
    end
  end

  @spec format_file_list([binary()]) :: binary()
  defp format_file_list(files) do
    Enum.join(files, "\n")
  end

  @spec format_text_output(binary()) :: binary()
  defp format_text_output(""), do: "OK"
  defp format_text_output(output), do: output

  @spec format_error_message(binary()) :: binary()
  defp format_error_message(message) do
    "Error: #{message}"
  end
end