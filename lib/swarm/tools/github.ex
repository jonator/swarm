defmodule Swarm.Tools.GitHub do
  @moduledoc false

  require Logger
  alias LangChain.Function
  alias LangChain.FunctionParam
  alias Swarm.Services.GitHub

  def all_tools(_mode \\ :read_write) do
    [
      create_pr(),
      acknowledge(),
      reply()
    ]
  end

  def create_pr do
    Function.new!(%{
      name: "create_pr",
      description: "Creates a pull request for the current branch.",
      parameters: [
        FunctionParam.new!(%{
          name: "title",
          type: :string,
          description: "The title of the pull request.",
          required: true
        }),
        FunctionParam.new!(%{
          name: "body",
          type: :string,
          description: "The body/description of the pull request.",
          required: true
        })
      ],
      function: fn %{"title" => title, "body" => body},
                   %{
                     "git_repo" => git_repo,
                     "repository" => repository,
                     "organization" => org,
                     "agent" => agent
                   } ->
        attrs = %{
          "title" => title,
          "body" => body,
          "head" => git_repo.branch,
          "base" => git_repo.base_branch
        }

        case GitHub.create_pull(org, repository.name, attrs) do
          {:ok, %{id: pr_id, number: pr_number, html_url: url}} ->
            Swarm.Agents.update_agent(agent, %{
              external_ids:
                Map.put(agent.external_ids, "github_pull_request_id", pr_id)
                |> Map.put("github_pull_request_url", url)
                |> Map.put("github_pull_request_number", pr_number)
            })

            {:ok, "Created pull request ##{pr_number}"}

          {:error, error_message} ->
            {:error, error_message}
        end
      end
    })
  end

  def acknowledge do
    Function.new!(%{
      name: "acknowledge",
      description: "Acknowledges a GitHub issue or comment with an emoji reaction.",
      parameters: [],
      function: fn _args,
                   %{"agent" => %{:external_ids => external_ids}, "repository" => repository} ->
        repository = Swarm.Repo.preload(repository, :organization)

        case external_ids do
          %{"github_issue_number" => _issue_number, "github_comment_id" => comment_id} ->
            Swarm.Services.GitHub.comment_reaction_create(
              repository.organization,
              repository.name,
              comment_id,
              %{content: "eyes"}
            )

          %{"github_issue_number" => issue_number} ->
            Swarm.Services.GitHub.issue_reaction_create(
              repository.organization,
              repository.name,
              issue_number,
              %{content: "eyes"}
            )

          _ ->
            Logger.error(
              "GitHub.acknowledge/1 - required context not available: #{inspect(external_ids)}"
            )

            {:error, "required context not available to acknowledge in github"}
        end
      end
    })
  end

  def reply do
    Function.new!(%{
      name: "reply",
      description: "Replies to a GitHub issue.",
      parameters: [
        FunctionParam.new!(%{
          name: "message",
          type: :string,
          description: "The message to send as a reply.",
          required: true
        })
      ],
      function: fn %{"message" => message},
                   %{"agent" => %{:external_ids => external_ids}, "repository" => repository} ->
        repository = Swarm.Repo.preload(repository, :organization)

        case external_ids do
          %{"github_issue_number" => issue_number} ->
            with {:ok, _comment} <-
                   Swarm.Services.GitHub.create_issue_comment(
                     repository.organization,
                     repository.name,
                     issue_number,
                     message
                   ) do
              {:ok, "Replied to issue #{issue_number} on #{repository.owner}/#{repository.name}"}
            end

          _ ->
            Logger.error(
              "GitHub.reply/1 - required context \"github_issue_number\" not available: #{inspect(external_ids)}"
            )

            {:error, "required context not available to reply to github"}
        end
      end
    })
  end
end
