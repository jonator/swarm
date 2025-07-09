defmodule Swarm.Tools.Git do
  @moduledoc """
  Git Tools Collection for Swarm Agents

  This module provides a unified interface for all Git-related tools
  that can be used by Swarm agents. It combines repository operations
  and index management tools into a single collection.

  ## Tool Categories

  - **Repository Tools**: File operations, staging, committing, pushing
  - **Index Tools**: Repository indexing and search capabilities

  ## Usage

  Tools are typically used within the context of an LLM chain where
  agents need to interact with Git repositories. The tools expect
  a git repository context to be available.

  ## Example

      # Get all tools for read-write operations
      tools = Swarm.Tools.Git.all_tools(:read_write)

      # Get only read-only tools
      read_tools = Swarm.Tools.Git.all_tools(:read)

  """

  alias Swarm.Tools.Git.Repo
  alias Swarm.Tools.Git.Index

  @type tool_mode :: :read | :read_write

  @doc """
  Returns all available Git tools based on the specified mode.

  ## Parameters
    - mode: Tool access mode (default: `:read_write`)
      - `:read` - Only read-only operations (list, open, status)
      - `:read_write` - All operations including write operations

  ## Returns
    - List of LangChain.Function structs representing available tools

  ## Examples

      # Get all tools for full repository access
      iex> Swarm.Tools.Git.all_tools(:read_write)
      [%LangChain.Function{name: "list_files"}, ...]

      # Get only read-only tools for safe operations
      iex> Swarm.Tools.Git.all_tools(:read)
      [%LangChain.Function{name: "list_files"}, ...]

  """
  @spec all_tools(tool_mode()) :: [LangChain.Function.t()]
  def all_tools(mode \\ :read_write) do
    repo_tools = Repo.all_tools(mode)
    index_tools = Index.all_tools(mode)

    repo_tools ++ index_tools
  end

  @doc """
  Returns only repository-related tools.

  ## Parameters
    - mode: Tool access mode (default: `:read_write`)

  ## Returns
    - List of repository operation tools
  """
  @spec repo_tools(tool_mode()) :: [LangChain.Function.t()]
  def repo_tools(mode \\ :read_write) do
    Repo.all_tools(mode)
  end

  @doc """
  Returns only index-related tools.

  ## Parameters
    - mode: Tool access mode (default: `:read_write`)

  ## Returns
    - List of index operation tools
  """
  @spec index_tools(tool_mode()) :: [LangChain.Function.t()]
  def index_tools(mode \\ :read_write) do
    Index.all_tools(mode)
  end

  @doc """
  Returns a summary of available tools by category.

  ## Returns
    - Map with tool categories and their descriptions
  """
  @spec tool_summary() :: map()
  def tool_summary do
    %{
      repository: %{
        description: "File and Git repository operations",
        tools: [
          "list_files - List all files in the repository",
          "open_file - Read file contents",
          "write_file - Write content to files",
          "rename_file - Rename files",
          "status - Check repository status",
          "add_file - Stage individual files",
          "add_all_files - Stage all changes",
          "commit - Commit staged changes",
          "push_origin - Push to remote repository"
        ]
      },
      index: %{
        description: "Repository indexing and search capabilities",
        tools: [
          "search - Search through repository content",
          "symbolic_analysis - Analyze code structure"
        ]
      }
    }
  end
end