Module.create(
  H,
  quote do
    @repo_url "https://github.com/polaris-portal/polaris"

    @instructions """
    in tokenInfoPageUrl in ui/apps/web/src/hooks/token-info/use-token-info-url-actions.ts, handle the new route Token RouteProps (to be set as fromRoken) being the same as the already set currentTo.
    Clear currentTo if chain ID and denom are the same. Ignore app folder, focus on token info page.

    Issue description:
    Strange behavior selecing USDC:base balance with query params. Upon clicking query params temporarily switch to base USDC then revert to screenshot selection.
    I believe it's because it's trying to set the from asset as the same as to asset. We should notice this then move the from selection to the "to" selection.
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
  end,
  Macro.Env.location(__ENV__)
)

IO.puts("iex config loaded")
