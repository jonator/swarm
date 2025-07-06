defmodule Swarm.Agents.LLMChain do
  @moduledoc """
  Common LLM chain setup utilities for Swarm agents.

  This module provides shared functionality for setting up LangChain LLM chains
  with consistent streaming handlers and configuration across different agent types.
  """

  require Logger

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatAnthropic
  alias Swarm.Agents.Agent
  alias Swarm.Agents.Message

  @doc """
  Creates a new LLM chain with common configuration.

  ## Options

  - `:model` - The model to use (default: "claude-sonnet-4-20250514")
  - `:max_tokens` - Maximum tokens for the model (default: 8192)
  - `:temperature` - Temperature for the model (default: 0.5)
  - `:custom_context` - Custom context to pass to the chain
  - `:verbose` - Whether to enable verbose logging (default: `Logger.level() == :debug`)
  - `:agent` - The agent instance for broadcasting messages

  ## Examples

      iex> chain = LLMChain.create(agent: agent, max_tokens: 64000, temperature: 0.7)
      iex> chain = LLMChain.add_messages(chain, messages)
      iex> chain = LLMChain.add_tools(chain, tools)
      iex> {:ok, result, _} = LLMChain.run_until_tool_used(chain, "finished")
  """
  def create(opts \\ []) do
    model = Keyword.get(opts, :model, "claude-sonnet-4-20250514")
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
  Runs the LLM chain until the specified tool is used.

  This is a convenience function that wraps `LLMChain.run_until_tool_used/2`
  with consistent error handling.
  """
  def run_until_finished(chain, tool_name \\ "finished") do
    case LLMChain.run_until_tool_used(chain, tool_name) do
      {:ok, updated_chain, _matching_call} ->
        Logger.info("LLM chain completed successfully")
        {:ok, updated_chain.last_message.content}

      {:error, _chain, reason} ->
        Logger.error("LLM chain failed: #{inspect(reason)}")
        {:error, "LLM chain failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Creates a finished tool that can be used to signal completion.
  """
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
  defp create_streaming_handler(%Agent{id: agent_id}) do
    %{
      on_llm_new_delta: fn _model, deltas ->
        Enum.each(List.wrap(deltas), fn delta ->
          # Extract the actual content from the ContentPart struct
          content = extract_content(delta)

          SwarmWeb.Endpoint.broadcast("agent:#{agent_id}", "message_delta", %{
            delta: content
          })
        end)
      end,
      on_message_processed: fn _chain, %LangChain.Message{} = message ->
        # Convert LangChain.Message to attrs using the Message module function
        message_attrs = Message.attrs_from_langchain_message(message)
        message_index = Swarm.Agents.get_next_message_index(agent_id)
        message_attrs = Map.put(message_attrs, :index, message_index)

        # Extract the content for broadcasting (keeping the same structure for frontend)
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

        SwarmWeb.Endpoint.broadcast("agent:#{agent_id}", "message", message_map)

        {:ok, _message} =
          Swarm.Agents.create_message(agent_id, message_attrs)
      end
    }
  end

  # Helper function to extract content from delta
  defp extract_content(%{content: %{content: text}}) when is_binary(text), do: text
  defp extract_content(%{content: text}) when is_binary(text), do: text
  defp extract_content(_), do: ""
end
