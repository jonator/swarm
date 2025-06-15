defmodule Swarm.OrganizationsFixtures do
  alias Swarm.Accounts.User

  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Organizations` context.
  """

  @doc """
  Generate a organization.
  """
  def organization_fixture(attrs \\ %{}) do
    {:ok, organization} =
      attrs
      |> Enum.into(%{
        name: "some-name"
      })
      |> Swarm.Organizations.create_organization()

    organization
  end

  @doc """
  Generate a personal organization for a user.
  """
  def personal_organization_fixture(%User{} = user, attrs \\ %{}) do
    default_attrs = %{
      github_installation_id: System.unique_integer([:positive])
    }

    merged_attrs = Enum.into(attrs, default_attrs)

    {:ok, organization} =
      Swarm.Organizations.get_or_create_organization(
        user,
        user.username,
        merged_attrs.github_installation_id
      )

    organization
  end
end
