defmodule Swarm.Framework do
  def detect(%Swarm.Git.Repo{} = repo) do
    case Swarm.Framework.Nextjs.detect(repo) do
      {:ok, nextjs} ->
        {:ok, nextjs}

      {:error, reason} ->
        {:error, "Failed to detect framework: #{reason}"}
    end
  end
end
