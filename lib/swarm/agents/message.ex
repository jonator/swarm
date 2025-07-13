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
    |> validate_required([:index, :type, :agent_id])
  end

  @doc """
  Converts a LangChain.Message struct to attributes suitable for database storage.

  The function extracts all relevant data from the LangChain.Message struct and
  converts it to a plain map that can be serialized to JSONB.
  """
  def attrs_from_langchain_message(%LangChain.Message{} = message) do
    content = %{
      raw_content: extract_content(message.content),
      processed_content: deep_extract_structs(message.processed_content),
      status: message.status,
      role: message.role,
      name: message.name,
      tool_calls: extract_tool_calls(message.tool_calls),
      tool_results: extract_tool_results(message.tool_results),
      metadata: extract_metadata(message.metadata)
    }

    %{
      content: deep_extract_structs(content),
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
          options: extract_options(options)
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
  defp extract_content(content), do: inspect(content)

  # Deep extraction function to ensure no structs remain anywhere in the data
  defp deep_extract_structs(value) when is_map(value) do
    if Map.has_key?(value, :__struct__) do
      # Convert struct to map and recursively extract
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

  # Helper function to extract options from ContentPart
  defp extract_options(options) when is_list(options) do
    Enum.map(options, fn
      {key, value} when is_map(value) ->
        {key, extract_nested_map(value)}

      {key, value} ->
        {key, value}

      other ->
        inspect(other)
    end)
  end

  defp extract_options(options) when is_map(options) do
    extract_nested_map(options)
  end

  defp extract_options(options), do: options

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
          arguments: deep_extract_structs(arguments),
          index: index
        }

      other ->
        %{type: :unknown, content: inspect(other)}
    end)
    |> deep_extract_structs()
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
          content: deep_extract_structs(content),
          processed_content: deep_extract_structs(processed_content),
          display_text: display_text,
          is_error: is_error,
          options: deep_extract_structs(options)
        }

      other ->
        %{type: :unknown, content: inspect(other)}
    end)
    |> deep_extract_structs()
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
        {key, deep_extract_structs(value)}
    end)
    |> Enum.into(%{})
    |> deep_extract_structs()
  end

  defp extract_metadata(nil), do: %{}
  defp extract_metadata(metadata), do: deep_extract_structs(metadata)

  # Helper function to extract nested maps and structs
  defp extract_nested_map(map) when is_map(map) do
    if Map.has_key?(map, :__struct__) do
      # Convert struct to map, excluding the __struct__ key
      map
      |> Map.from_struct()
      |> Enum.map(fn {key, value} -> {key, deep_extract_structs(value)} end)
      |> Enum.into(%{})
    else
      map
      |> Enum.map(fn {key, value} -> {key, deep_extract_structs(value)} end)
      |> Enum.into(%{})
    end
  end
end
