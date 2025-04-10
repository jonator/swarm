Module.create(
  H,
  quote do
    @repo_url "https://github.com/polaris-portal/polaris"

    @instructions """
    Filter OKX from cosmos/useWalletOptions and remove existing connections

    Filter any wallet with name "OKX" from response in ui/apps/web/src/ecosystems/cosmos/use-wallet-options.ts.
    Add code that checks if it's connected and call disconnect() if it is. Maybe in a useEffect.

    connectedWalletOption returns current connected wallets, which would include OKX if it's connected in the name of the wallet.

    Types are defined at ui/apps/web/src/hooks/wallet/use-wallet-options.ts

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
  end,
  Macro.Env.location(__ENV__)
)

IO.puts("iex config loaded")
