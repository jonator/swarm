defmodule Swarm.RepositoriesFixtures do
  alias Swarm.Accounts.User
  import Swarm.AccountsFixtures
  import Swarm.OrganizationsFixtures

  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Repositories` context.
  """

  @doc """
  Generate a repository, comes with user and personal organization.
  """
  def repository_fixture(%User{} = user \\ user_fixture(), attrs \\ %{}) do
    # Create a personal organization for the user if it doesn't exist
    _organization = personal_organization_fixture(user)

    {:ok, repository} =
      Swarm.Repositories.create_repository(
        user,
        attrs
        |> Enum.into(%{
          external_id: "github:#{System.unique_integer([:positive])}",
          name: "some/name",
          owner: user.username
        })
      )

    repository
  end
end
