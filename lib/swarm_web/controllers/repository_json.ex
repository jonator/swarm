defmodule SwarmWeb.RepositoryJSON do
  alias Swarm.Repositories.Repository

  @doc """
  Renders a list of repositories.
  """
  def index(%{repositories: repositories}) do
    %{data: for(repository <- repositories, do: data(repository))}
  end

  @doc """
  Renders a single repository.
  """
  def show(%{repository: repository}) do
    %{data: data(repository)}
  end

  defp data(%Repository{} = repository) do
    %{
      id: repository.id,
      name: repository.name,
      owner: repository.owner,
      created_at: repository.inserted_at,
      updated_at: repository.updated_at
    }
  end
end
