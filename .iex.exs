Module.create(
  H,
  quote do
    def as() do
      Swarm.Agents.stream_repository_agents(1) |> Enum.each(&IO.inspect/1)
    end
  end,
  Macro.Env.location(__ENV__)
)

IO.puts("iex config loaded")
