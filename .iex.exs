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
      Swarm.Accounts.get_user_by_username("test")
    end

    def repo_attr() do
      %{
        name: "repo",
        owner: "owner",
        projects: [
          %{type: "nextjs"}
        ]
      }
    end

    alias LangChain.Message
    alias LangChain.MessageDelta
    alias LangChain.Chains.LLMChain
    alias LangChain.ChatModels.ChatAnthropic

    def c do
      handler = %{
        on_llm_new_delta: fn _model, %MessageDelta{} = data ->
          # we received a piece of data
          IO.write(data.content)
        end,
        on_message_processed: fn _chain, %Message{} = data ->
          # the message was assembled and is processed
          IO.puts("")
          IO.puts("")
          IO.inspect(data.content, label: "COMPLETED MESSAGE")
        end
      }

      {:ok, updated_chain} =
        %{
          # llm config for streaming and the deltas callback
          llm: ChatAnthropic.new!(%{model: "claude-3-5-sonnet-20241022", stream: true})
        }
        |> LLMChain.new!()
        |> LLMChain.add_messages([
          Message.new_system!("You are a helpful assistant."),
          Message.new_user!("Write a haiku about the capital of the United States")
        ])
        # register the callbacks
        |> LLMChain.add_callback(handler)
        |> LLMChain.run()
    end
  end,
  Macro.Env.location(__ENV__)
)

IO.puts("iex config loaded")
