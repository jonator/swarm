Module.create(
  H,
  quote do
    # def as() do
    #   Swarm.Agents.stream_repository_agents(1) |> Enum.each(&IO.inspect/1)
    # end

    def tmp(str) do
      path = Path.join(System.tmp_dir!(), "my_temp_file.txt")
      File.write!(path, str)
      IO.puts("Wrote data to: #{path}")
    end
  end,
  Macro.Env.location(__ENV__)
)

IO.puts("iex config loaded")
