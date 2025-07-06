defmodule Swarm.Agents.Message do
  @moduledoc """
  Schema for agent messages that represent communication during agent execution.

  Messages follow the LangChain message format with types for system, user, assistant, and tool messages.
  Each message belongs to an agent and contains content for conversation tracking.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Swarm.Agents.Agent

  schema "agent_messages" do
    # See: https://hexdocs.pm/langchain/LangChain.Message.html
    field :index, :integer
    field :type, Ecto.Enum, values: [:system, :user, :assistant, :tool]
    field :content, :map
    belongs_to :agent, Agent, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :index, :type, :agent_id])
    |> validate_required([:content, :index, :type, :agent_id])
  end

  @doc """
  Converts a LangChain.Message struct to attributes suitable for database storage.

  The function extracts all relevant data from the LangChain.Message struct and
  converts it to a plain map that can be serialized to JSONB.
  """
  def attrs_from_langchain_message(%LangChain.Message{} = message) do
    %{
      content: %{
        raw_content: extract_content(message.content),
        processed_content: message.processed_content,
        status: message.status,
        role: message.role,
        name: message.name,
        tool_calls: extract_tool_calls(message.tool_calls),
        tool_results: extract_tool_results(message.tool_results),
        metadata: extract_metadata(message.metadata)
      },
      index: message.index,
      type: message.role
    }
  end

  # Helper function to extract content from LangChain.Message content
  defp extract_content(content) when is_list(content) do
    Enum.map(content, fn
      %LangChain.Message.ContentPart{type: type, content: text, options: options} ->
        %{
          type: type,
          content: text,
          options: options
        }

      %{type: type, content: text} ->
        %{type: type, content: text}

      %{content: text} when is_binary(text) ->
        %{type: :text, content: text}

      other ->
        %{type: :unknown, content: inspect(other)}
    end)
  end

  defp extract_content(content) when is_binary(content), do: content
  defp extract_content(nil), do: nil
  defp extract_content([]), do: []

  # Helper function to extract tool calls
  defp extract_tool_calls(tool_calls) when is_list(tool_calls) do
    Enum.map(tool_calls, fn
      %LangChain.Message.ToolCall{
        status: status,
        type: type,
        call_id: call_id,
        name: name,
        arguments: arguments,
        index: index
      } ->
        %{
          status: status,
          type: type,
          call_id: call_id,
          name: name,
          arguments: arguments,
          index: index
        }

      other ->
        %{type: :unknown, content: inspect(other)}
    end)
  end

  defp extract_tool_calls(nil), do: []
  defp extract_tool_calls([]), do: []

  # Helper function to extract tool results
  defp extract_tool_results(tool_results) when is_list(tool_results) do
    Enum.map(tool_results, fn
      %LangChain.Message.ToolResult{
        type: type,
        tool_call_id: tool_call_id,
        name: name,
        content: content,
        processed_content: processed_content,
        display_text: display_text,
        is_error: is_error,
        options: options
      } ->
        %{
          type: type,
          tool_call_id: tool_call_id,
          name: name,
          content: content,
          processed_content: processed_content,
          display_text: display_text,
          is_error: is_error,
          options: options
        }

      other ->
        %{type: :unknown, content: inspect(other)}
    end)
  end

  defp extract_tool_results(nil), do: []
  defp extract_tool_results([]), do: []

  # Helper function to extract metadata
  defp extract_metadata(metadata) when is_map(metadata) do
    metadata
    |> Enum.map(fn
      {:usage, %LangChain.TokenUsage{input: input, output: output, raw: raw}} ->
        {:usage, %{input: input, output: output, raw: raw}}

      {key, value} when is_map(value) ->
        # Handle nested maps by recursively extracting
        {key, extract_nested_map(value)}

      {key, value} ->
        {key, value}
    end)
    |> Enum.into(%{})
  end

  defp extract_metadata(nil), do: %{}
  defp extract_metadata(metadata), do: metadata

  # Helper function to extract nested maps and structs
  defp extract_nested_map(map) when is_map(map) do
    if Map.has_key?(map, :__struct__) do
      # Convert struct to map, excluding the __struct__ key
      map
      |> Map.from_struct()
      |> Enum.into(%{})
    else
      map
    end
  end
end
