defmodule Swarm.RepositoriesFixtures do
  alias Swarm.Accounts.User

  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Repositories` context.
  """

  @doc """
  Generate a repository.
  """
  def repository_fixture(%User{} = user, attrs \\ %{}) do
    {:ok, repository} =
      Swarm.Repositories.create_repository(
        user,
        attrs
        |> Enum.into(%{
          name: "some/name",
          owner: "some_owner"
        })
      )

    repository
  end
end
