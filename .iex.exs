Module.create(
  H,
  quote do
    def tj(instructions \\ "I'm looking to improve the changelog formatting") do
      %{
        url: "https://github.com/thmsmlr/instructor_ex.git",
        branch: "test",
        instructions: instructions
      }
    end

    def tr(id \\ 1) do
      Swarm.GitRepo.open("https://github.com/thmsmlr/instructor_ex.git", to_string(id), "test")
    end

    def ti(instructions \\ "I'm looking to improve the changelog formatting") do
      tj(instructions) |> Swarm.Worker.Implement.new() |> Oban.insert()
    end
  end,
  Macro.Env.location(__ENV__)
)

IO.puts("iex config loaded")
