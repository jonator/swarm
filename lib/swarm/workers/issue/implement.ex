defmodule Swarm.Workers.Issue.Implement do
  use Oban.Worker, queue: :default

  def perform(job) do

    # Sleep for 30 seconds
    Process.sleep(30_000)
    IO.inspect(job)
  end
end
