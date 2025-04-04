Module.create(
  H,
  quote do
    @repo_url "https://github.com/thmsmlr/instructor_ex.git"

    def tjj(instructions \\ "I'm looking to improve the changelog formatting") do
      %{
        url: @repo_url,
        branch: "test",
        instructions: instructions
      }
    end

    def tj(instructions \\ "I'm looking to improve the changelog formatting") do
      tjj(instructions) |> Swarm.Worker.Implement.new() |> Oban.insert()
    end

    def tr(id \\ 1) do
      {:ok, repo} = Swarm.Git.Repo.open(@repo_url, to_string(id), "test")
      repo
    end

    def i() do
      start_time = System.monotonic_time(:millisecond)
      {:ok, index} = Swarm.Git.Index.from_repo(tr())
      end_time = System.monotonic_time(:millisecond)
      IO.puts("Index creation took #{end_time - start_time}ms")
      index
    end
  end,
  Macro.Env.location(__ENV__)
)

IO.puts("iex config loaded")
