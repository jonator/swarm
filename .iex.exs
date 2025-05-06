Module.create(
  H,
  quote do
    @repo_url "https://github.com/polaris-portal/polaris.git"

    @instructions """
    in ui/turbo.json ensure that AUTH_CLIENT_SECRET and AUTH_SECRET are added to globalEnv array.
    Ignore app folder.
    """

    def tjj(instructions \\ @instructions) do
      %{
        repo_url: @repo_url,
        instructions: instructions
      }
    end

    def tj(instructions \\ @instructions) do
      tjj(instructions) |> Swarm.Worker.Implement.new() |> Oban.insert()
    end

    def tr(id \\ 1) do
      {:ok, repo} = Swarm.Git.Repo.open(@repo_url, to_string(id), "test")
      repo
    end

    def ti(id \\ 1) do
      {:ok, index} = Swarm.Git.Index.from(tr(id), [~r/app\/.*/])
      index
    end

    def i() do
      start_time = System.monotonic_time(:millisecond)
      {:ok, index} = Swarm.Git.Index.from(tr())
      end_time = System.monotonic_time(:millisecond)
      IO.puts("Index creation took #{end_time - start_time}ms")
      index
    end

    def user() do
      Swarm.Accounts.get_user_by_email("test@email.com")
    end

    def repo_attr() do
      %{
        name: "test/repo",
        applications: [
          %{type: "nextjs"}
        ]
      }
    end
  end,
  Macro.Env.location(__ENV__)
)

IO.puts("iex config loaded")
