defmodule Swarm.RepositoriesFixtures do
  alias Swarm.Accounts.User
  import Swarm.AccountsFixtures

  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Repositories` context.
  """

  @doc """
  Generate a repository, comes with user.
  """
  def repository_fixture(%User{} = user \\ user_fixture(), attrs \\ %{}) do
    {:ok, repository} =
      Swarm.Repositories.create_repository(
        user,
        attrs
        |> Enum.into(%{
          name: "some/name",
          owner: "User"
        })
      )

    repository
  end
end
