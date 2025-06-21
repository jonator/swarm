defmodule Swarm.Egress do
  @moduledoc """
  Egress module for sending messages or data to external systems.
  """

  alias Swarm.Repositories.Repository
  alias Swarm.Ingress.Event
  alias Swarm.Egress.LinearDispatch
  alias Swarm.Egress.GitHubDispatch

  @doc """
  Acknowledge a message.

  Per recommendation: https://linear.app/developers/agents#recommendations
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

  def reply(
        %{"linear_issue_id" => _, "linear_app_user_id" => _} =
          external_ids,
        message
      ) do
    LinearDispatch.reply(external_ids, message)
  end

  def reply(
        %{"github_issue_number" => _, "github_repo_full_name" => _} =
          external_ids,
        message
      ) do
    GitHubDispatch.reply(external_ids, message)
  end

  def reply(%Event{source: other_source}, _message) do
    {:error, "Egress.reply/1 received non-supported event source: #{other_source}"}
  end
end
