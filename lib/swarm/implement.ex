defmodule Swarm.Implement do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{id: id, args: %{"url" => url, "branch" => branch}}) do
    IO.inspect(url, label: "URL")
    IO.inspect(branch, label: "BRANCH")
    IO.inspect(id, label: "ID")

    {:ok, repo} = Swarm.GitRepo.open(url, to_string(id), branch)

    IO.inspect(repo, label: "REPO")

    :ok
  end
end
