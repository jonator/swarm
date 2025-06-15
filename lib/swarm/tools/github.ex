defmodule Swarm.Tools.GitHub do
  @moduledoc false

  alias LangChain.Function
  alias LangChain.FunctionParam
  alias Swarm.Services.GitHub

  def all_tools do
    [
      create_pr()
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
                   %{"git_repo" => git_repo, "repository" => repository, "organization" => org} ->
        name = Map.get(repository, :name)

        attrs = %{
          "title" => title,
          "body" => body,
          "head" => git_repo.branch,
          "base" => git_repo.base_branch
        }

        case GitHub.create_pull(org, name, attrs) do
          {:ok, pr_number} -> {:ok, %{pr_number: pr_number}}
          error -> error
        end
      end
    })
  end
end
