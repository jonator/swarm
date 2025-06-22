defmodule Swarm.RepositoriesFixtures do
  alias Swarm.Accounts.User
  alias Swarm.Repositories
  alias Swarm.Organizations.Organization
  import Swarm.AccountsFixtures
  import Swarm.OrganizationsFixtures

  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Repositories` context.
  """

  @doc """
  Generate a repository, comes with user and personal organization.
  """
  def repository_fixture(entity \\ user_fixture(), attrs \\ %{})

  def repository_fixture(%User{} = user, attrs) do
    # Create a personal organization for the user if it doesn't exist
    _organization = personal_organization_fixture(user)

    {:ok, repository} =
      Repositories.create_repository(
        user,
        attrs
        |> Enum.into(%{
          external_id: "github:#{System.unique_integer([:positive])}",
          name: "name",
          owner: user.username
        })
      )

    repository
  end

  def repository_fixture(%Organization{} = organization, attrs) do
    {:ok, repository} =
      Repositories.create_repository(
        organization,
        attrs
        |> Enum.into(%{
          external_id: "github:#{System.unique_integer([:positive])}",
          name: "name",
          owner: organization.name
        })
      )

    repository
  end
end
