defmodule SwarmWeb.RepositoryJSON do
  alias Swarm.Repositories.Repository

  @doc """
  Renders a list of repositories.
  """
  def index(%{repositories: repositories}) do
    %{repositories: for(repository <- repositories, do: data(repository))}
  end

  @doc """
  Renders a single repository.
  """
  def show(%{repository: repository}) do
    %{repository: data(repository)}
  end

  defp data(%Repository{} = repository) do
    %{
      id: repository.id,
      external_id: repository.external_id,
      name: repository.name,
      owner: repository.owner,
      linear_team_external_ids: repository.linear_team_external_ids,
      created_at: repository.inserted_at,
      updated_at: repository.updated_at,
      organization_id: repository.organization_id
    }
  end
end
