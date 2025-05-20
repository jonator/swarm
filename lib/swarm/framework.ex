defmodule Swarm.Framework do
  @moduledoc false

  alias Swarm.Framework.Nextjs

  def detect(%Swarm.Git.Repo{} = repo) do
    case Swarm.Framework.Nextjs.detect(repo) do
      {:ok, nextjs} ->
        {:ok, nextjs}

      {:error, reason} ->
        {:error, "Failed to detect framework: #{reason}"}
    end
  end

  @doc """
  Detects project types amongst a given GitHub repository tree.

  ## Examples

      iex> tree = %{
      ...>   "tree" => [
      ...>     %{
      ...>       "mode" => "040000",
      ...>       "path" => "lib/swarm/agent",
      ...>       "sha" => "1fdb19e7560a928b1e31af4dc44e3dfefff48188",
      ...>       "type" => "tree",
      ...>       "url" => "https://api.github.com/repos/jonator/swarm/git/trees/1fdb19e7560a928b1e31af4dc44e3dfefff48188"
      ...>     },
      ...>     %{
      ...>       "mode" => "100644",
      ...>       "path" => "lib/swarm/agent/implementor.ex",
      ...>       "sha" => "4a28ab0d568e6ca3cb9597cf719b05b81ae03dea",
      ...>       "size" => 1653,
      ...>       "type" => "blob",
      ...>       "url" => "https://api.github.com/repos/jonator/swarm/git/blobs/4a28ab0d568e6ca3cb9597cf719b05b81ae03dea"
      ...>     },
      ...>   ]
      ...> }
      ...> Swarm.Framework.detect(tree)
      ...> [%{type: "nextjs", path: "frontend"}]
  """
  def detect(%{"tree" => trees}) do
    Enum.reduce(trees, [], fn tree, acc ->
      if tree["type"] == "blob" && Nextjs.detect(tree["path"]) do
        [%{type: Nextjs.key, path: Path.dirname(tree["path"])} | acc]
      else
        acc
      end
    end)
  end
end
