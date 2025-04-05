defmodule Swarm.Tool.GitRepo do
  alias LangChain.Function
  alias LangChain.FunctionParam

  def all_tools do
    [
      add_file(),
      add_all_files(),
      commit(),
      rename_file(),
      list_files(),
      open_file(),
      write_file(),
      status()
    ]
  end

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
      function: fn %{"file" => file} = _arguments, %{"repo" => repo} ->
        Swarm.Git.Repo.add_file(repo, file) |> handle_repo_response()
      end
    })
  end

  def add_all_files do
    Function.new!(%{
      name: "add_all_files",
      description: "Adds all files to the staging area of the git repository.",
      parameters: [],
      function: fn _arguments, %{"repo" => repo} ->
        Swarm.Git.Repo.add_all_files(repo) |> handle_repo_response()
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
      function: fn %{"message" => message} = _arguments, %{"repo" => repo} ->
        Swarm.Git.Repo.commit(repo, message) |> handle_repo_response()
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
                   %{"repo" => repo} ->
        Swarm.Git.Repo.rename_file(repo, old_file, new_file) |> handle_repo_response()
      end
    })
  end

  def list_files do
    Function.new!(%{
      name: "list_files",
      description: "Lists all relative file paths in the git repository.",
      parameters: [],
      function: fn _arguments, %{"repo" => repo} ->
        case Swarm.Git.Repo.list_files(repo) do
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
      function: fn %{"file" => file} = _arguments, %{"repo" => repo} ->
        Swarm.Git.Repo.open_file(repo, file) |> handle_repo_response()
      end
    })
  end

  def write_file do
    Function.new!(%{
      name: "write_file",
      description: "Writes content to a file in the git repository.",
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
      function: fn %{"file" => file, "content" => content} = _arguments, %{"repo" => repo} ->
        Swarm.Git.Repo.write_file(repo, file, content) |> handle_repo_response()
      end
    })
  end

  def status do
    Function.new!(%{
      name: "status",
      description: "Returns the status of the git repository.",
      parameters: [],
      function: fn _arguments, %{"repo" => repo} ->
        Swarm.Git.Repo.status(repo) |> handle_repo_response()
      end
    })
  end

  defp handle_repo_response({:ok, output}) when is_binary(output) do
    if output == "", do: "OK", else: output
  end

  defp handle_repo_response({:ok, _}), do: "OK"
  defp handle_repo_response({:error, msg}), do: "Error: #{msg}"
end
