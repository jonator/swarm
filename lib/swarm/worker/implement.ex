defmodule Swarm.Worker.Implement do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{"url" => url, "branch" => branch, "instructions" => instructions}
      }) do
    {:ok, repo} = Swarm.Git.Repo.open(url, to_string(id), branch)

    # Get relevant files
    relevant_files =
      Swarm.Instructor.RelevantFiles.get_relevant_files(
        repo,
        instructions
      )

    # Create search index in parallel
    {:ok, index} = Swarm.Git.Index.from_repo(repo)

    IO.inspect(Search.search(index, "error"))

    IO.inspect(relevant_files, label: "RELEVANT FILES")

    :ok
  end
end
