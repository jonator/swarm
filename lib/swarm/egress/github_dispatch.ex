defmodule Swarm.Egress.GitHubDispatch do
  @moduledoc """
  Egress module for sending messages or data to GitHub.
  """

  alias Swarm.Ingress.Event
  alias Swarm.Repo
  alias Swarm.Repositories.Repository
  alias Swarm.Services.GitHub

  @acknowledge_emoji "eyes"

  def acknowledge(
        %Event{
          source: :github,
          external_ids: %{
            "github_issue_number" => _issue_number,
            "github_comment_id" => comment_id
          }
        },
        %Repository{} = repository
      ) do
    repository = Repo.preload(repository, :organization)

    GitHub.comment_reaction_create(
      repository.organization,
      repository.name,
      comment_id,
      %{content: @acknowledge_emoji}
    )
  end

  def acknowledge(
        %Event{
          source: :github,
          external_ids: %{
            "github_issue_number" => issue_number
          }
        },
        %Repository{} = repository
      ) do
    repository = Repo.preload(repository, :organization)

    GitHub.issue_reaction_create(
      repository.organization,
      repository.name,
      issue_number,
      %{content: @acknowledge_emoji}
    )
  end

  def acknowledge(event, _repository) do
    {:error, "Egress.GitHub.acknowledge/1 - event not supported: #{inspect(event)}"}
  end

  @doc """
  Reply to a GitHub issue event.
  """
  def reply(
        %{"github_issue_number" => issue_number},
        %Repository{} = repository,
        message
      ) do
    repository = Swarm.Repo.preload(repository, :organization)

    with {:ok, _comment} <-
           GitHub.create_issue_comment(
             repository.organization,
             repository.name,
             issue_number,
             message
           ) do
      {:ok, "Replied to issue #{issue_number} on #{repository.owner}/#{repository.name}"}
    else
      error -> {:error, "Failed to reply to GitHub issue: #{inspect(error)}"}
    end
  end

  def reply(external_ids, _repository, _message) do
    {:error, "Egress.GitHub.reply/3 - external_ids not supported: #{inspect(external_ids)}"}
  end
end
