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

  def reply(
        %Event{
          source: :github,
          external_ids: %{"github_issue_number" => issue_number}
        },
        %Repository{} = repository,
        body
      ) do
    with {:ok, _comment} <-
           GitHub.create_issue_comment(
             repository.owner,
             repository.name,
             issue_number,
             body
           ) do
      {:ok, "Replied to issue #{issue_number}"}
    end
  end

  def reply(event, _repository, _body) do
    {:error, "Egress.GitHub.reply/2 - event not supported: #{inspect(event)}"}
  end

  def reply(_event) do
    {:error, "Egress.GitHub.reply/1 - not supported, must provide event, repository, and body"}
  end
end
