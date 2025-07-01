Module.create(
  H,
  quote do
    # def as() do
    #   Swarm.Agents.stream_repository_agents(1) |> Enum.each(&IO.inspect/1)
    # end

    def tmp(str, filename \\ "my_temp_file.txt") do
      path = Path.join(System.tmp_dir!(), filename)
      File.write!(path, str)
      IO.puts("Wrote data to: #{path}")
    end

    def pla do
      Swarm.Agents.list_agents() |> Enum.each(&tmp(&1.context, &1.id <> ".txt"))
    end
  end,
  Macro.Env.location(__ENV__)
)

IO.puts("iex config loaded")
