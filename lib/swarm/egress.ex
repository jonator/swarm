defmodule Swarm.Egress do
  @moduledoc """
  Egress module for sending messages or data to external services.
  """

  alias Swarm.Ingress.Event
  alias Swarm.Repositories.Repository
  alias Swarm.Egress.{LinearDispatch, GitHubDispatch}

  @doc """
  Deprecated. Use Swarm.Tools for tool-based acknowledge.
  """
  def acknowledge(%Event{source: :linear} = event, _repository) do
    LinearDispatch.acknowledge(event)
  end

  def acknowledge(%Event{source: :github} = event, %Repository{} = repository) do
    GitHubDispatch.acknowledge(event, repository)
  end

  def acknowledge(%Event{source: other_source}, _repository) do
    {:error, "Egress.acknowledge/1 received non-supported event source: #{other_source}"}
  end

  def reply(%Event{source: :linear} = event, %Repository{} = repository, body) do
    LinearDispatch.reply(event, repository, body)
  end

  def reply(%Event{source: :github} = event, %Repository{} = repository, body) do
    GitHubDispatch.reply(event, repository, body)
  end
end
