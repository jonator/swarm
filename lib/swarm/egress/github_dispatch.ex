defmodule Swarm.Egress.GitHubDispatch do
  @moduledoc """
  Egress module for sending messages or data to GitHub.
  """

  alias Swarm.Ingress.Event

  @acknowledge_emoji "eyes"

  def acknowledge(%Event{
        source: :github,
        external_ids: %{
          "github_repo_full_name" => _repo_full_name,
          "github_issue_number" => _issue_number,
          "github_comment_id" => _comment_id
        }
      }) do
    # TODO: GitHub.create_comment_reaction(org, repo_full_name, comment_id, @acknowledge_emoji)
    {:ok, "not implemented"}
  end

  def acknowledge(%Event{
        source: :github,
        external_ids: %{
          "github_repo_full_name" => _repo_full_name,
          "github_issue_number" => _issue_number
        }
      }) do
    # TODO: GitHub.create_issue_reaction(org, repo_full_name, issue_number, @acknowledge_emoji)
    {:ok, "not implemented"}
  end

  def acknowledge(event) do
    {:error, "Egress.GitHub.acknowledge/1 - event not supported: #{inspect(event)}"}
  end

  @doc """
  Reply to a GitHub issue event.
  """
  def reply(
        %{
          "github_repo_full_name" => _repo_full_name,
          "github_issue_number" => _issue_number
        },
        _message
      ) do
    # TODO: GitHub.create_issue_comment(org, repo_full_name, issue_number, message)
    {:ok, "not implemented"}
  end

  def reply(event, _message) do
    {:error, "Egress.GitHub.reply/1 - event not supported: #{inspect(event)}"}
  end
end
