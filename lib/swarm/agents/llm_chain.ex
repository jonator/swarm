defmodule Swarm.Agents.LLMChain do
  @moduledoc """
  Advanced LLM chain management for Swarm agents.

  This module provides a robust and flexible implementation for setting up 
  Language Model (LLM) chains with:
  - Consistent streaming handlers
  - Configurable model parameters
  - Advanced error handling
  - Comprehensive message broadcasting

  ## Key Features
  - Dynamic model selection
  - Fallback model support
  - Streaming message updates
  - Detailed logging
  - Flexible configuration

  ## Example Usage
  ```elixir
  {:ok, result} = LLMChain.create(agent: agent)
  |> LLMChain.add_messages(initial_messages)
  |> LLMChain.add_tools(available_tools)
  |> LLMChain.run_until_finished()
  ```
  """

  require Logger

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatAnthropic
  alias LangChain.ChatModels.ChatOpenAI
  alias Swarm.Agents.Agent
  alias Swarm.Agents.Message
  alias Phoenix.PubSub

  @type model_config :: %{
          model: String.t(),
          max_tokens: non_neg_integer(),
          temperature: float(),
          stream: boolean()
        }

  @type chain_options :: [
          {:model, String.t()}
          | {:max_tokens, non_neg_integer()}
          | {:temperature, float()}
          | {:custom_context, map()}
          | {:verbose, boolean()}
          | {:agent, Agent.t()}
        ]

  @doc """
  Creates a new LLM chain with advanced configuration and error handling.

  ## Parameters
  - `opts`: Keyword list of configuration options

  ## Options
  - `:model` - LLM model identifier (default: "claude-3-5-haiku-latest")
  - `:max_tokens` - Maximum token limit (default: 8192)
  - `:temperature` - Creativity/randomness setting (default: 0.5)
  - `:custom_context` - Additional context for the chain (default: %{})
  - `:verbose` - Enable detailed logging (default: debug mode)
  - `:agent` - Associated Swarm agent

  ## Returns
  A configured `LLMChain` struct ready for message processing

  ## Examples
      iex> chain = LLMChain.create(agent: agent, max_tokens: 64000, temperature: 0.7)
  """
  @spec create(chain_options()) :: LLMChain.t()
  def create(opts \\ []) do
    model = Keyword.get(opts, :model, "claude-3-5-haiku-latest")
    max_tokens = Keyword.get(opts, :max_tokens, 8192)
    temperature = Keyword.get(opts, :temperature, 0.5)
    custom_context = Keyword.get(opts, :custom_context, %{})
    verbose = Keyword.get(opts, :verbose, Logger.level() == :debug)
    agent = Keyword.get(opts, :agent)

    chat_model =
      ChatAnthropic.new!(%{
        model: model,
        max_tokens: max_tokens,
        temperature: temperature,
        stream: true
      })

    handler = create_streaming_handler(agent)

    %{
      llm: chat_model,
      custom_context: custom_context,
      verbose: verbose
    }
    |> LLMChain.new!()
    |> LLMChain.add_callback(handler)
  end

  @doc """
  Executes the LLM chain until a specified tool is used.

  ## Parameters
  - `chain`: The LLMChain to execute
  - `tool_name`: Name of the tool signaling completion (default: "finished")

  ## Returns
  `{:ok, result}` with the final message content or `{:error, reason}`

  ## Fallback Strategy
  If the primary model fails, automatically switches to a backup model
  to ensure task completion.
  """
  @spec run_until_finished(LLMChain.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def run_until_finished(chain, tool_name \\ "finished") do
    fallback_model =
      ChatOpenAI.new!(%{
        model: "o3-mini-2025-01-31",
        stream: true
      })

    case LLMChain.run_until_tool_used(chain, tool_name,
           with_fallbacks: [fallback_model],
           max_runs: 50
         ) do
      {:ok, updated_chain, _matching_call} ->
        Logger.info("LLM chain completed successfully")
        {:ok, updated_chain.last_message.content}

      {:error, _chain, reason} ->
        error_msg = "LLM chain failed: #{inspect(reason)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc """
  Creates a tool to signal task completion.

  ## Parameters
  - `description`: Custom description for the finished tool

  ## Returns
  A LangChain function tool representing task completion
  """
  @spec create_finished_tool(String.t()) :: LangChain.Function.t()
  def create_finished_tool(description \\ "Indicates that the implementation is complete") do
    LangChain.Function.new!(%{
      name: "finished",
      description: description,
      parameters: [],
      function: fn _arguments, _context ->
        {:ok, description}
      end
    })
  end

  # Private function to create the streaming handler
  @spec create_streaming_handler(Agent.t()) :: map()
  defp create_streaming_handler(%Agent{id: agent_id}) do
    %{
      on_llm_new_delta: fn _model, deltas ->
        Enum.each(List.wrap(deltas), fn delta ->
          content = extract_content(delta)

          if content != "" do
            PubSub.broadcast(
              Swarm.PubSub,
              "agent:#{agent_id}",
              {"message_delta", %{delta: content}}
            )
          end
        end)
      end,
      on_message_processed: fn _chain, %LangChain.Message{} = message ->
        message_attrs = Message.attrs_from_langchain_message(message)
        message_index = Swarm.Agents.get_next_message_index(agent_id)
        message_attrs = Map.put(message_attrs, :index, message_index)

        message_map = %{
          content: message_attrs.content.raw_content,
          index: message_index,
          status: message_attrs.content.status,
          role: message_attrs.content.role,
          name: message_attrs.content.name,
          tool_calls: message_attrs.content.tool_calls,
          tool_results: message_attrs.content.tool_results,
          metadata: message_attrs.content.metadata
        }

        clean_message_map = deep_extract_structs(message_map)

        PubSub.broadcast(Swarm.PubSub, "agent:#{agent_id}", {"message", clean_message_map})

        {:ok, _message} =
          Swarm.Agents.create_message(agent_id, message_attrs)
      end
    }
  end

  # Helper function to extract content from delta
  @spec extract_content(map() | any()) :: String.t()
  defp extract_content(%{content: %{content: text}}) when is_binary(text), do: text
  defp extract_content(%{content: text}) when is_binary(text), do: text
  defp extract_content(_), do: ""

  # Deep extraction function to ensure no structs remain anywhere in the data
  @spec deep_extract_structs(any()) :: any()
  defp deep_extract_structs(value) when is_map(value) do
    if Map.has_key?(value, :__struct__) do
      value
      |> Map.from_struct()
      |> Enum.map(fn {key, val} -> {key, deep_extract_structs(val)} end)
      |> Enum.into(%{})
    else
      value
      |> Enum.map(fn {key, val} -> {key, deep_extract_structs(val)} end)
      |> Enum.into(%{})
    end
  end

  defp deep_extract_structs(value) when is_list(value) do
    Enum.map(value, &deep_extract_structs/1)
  end

  defp deep_extract_structs(value), do: value
end
