defmodule Swarm.RepositoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Repositories` context.
  """

  @doc """
  Generate a repository.
  """
  def repository_fixture(attrs \\ %{}) do
    {:ok, repository} =
      attrs
      |> Enum.into(%{
        name: "some/name",
        owner: "some_owner"
      })
      |> Swarm.Repositories.create_repository()

    repository
  end
end
