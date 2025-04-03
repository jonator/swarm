defmodule Swarm.Worker.Implement do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{"url" => url, "branch" => branch, "instructions" => instructions}
      }) do
    {:ok, repo} = Swarm.GitRepo.open(url, to_string(id), branch)

    relevant_files =
      Swarm.Instructor.RelevantFiles.get_relevant_files(
        repo,
        instructions
      )

    IO.inspect(relevant_files, label: "RELEVANT FILES")

    :ok
  end
end
