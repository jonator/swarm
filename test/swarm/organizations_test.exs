defmodule Swarm.OrganizationsTest do
  use Swarm.DataCase

  alias Swarm.Organizations
  alias Swarm.Accounts.UserOrganization

  describe "organizations" do
    alias Swarm.Organizations.Organization

    import Swarm.OrganizationsFixtures
    import Swarm.AccountsFixtures

    @invalid_attrs %{name: nil}

    test "list_organizations/0 returns all organizations" do
      organization = organization_fixture()
      assert Organizations.list_organizations() == [organization]
    end

    test "get_organization!/1 returns the organization with given id" do
      organization = organization_fixture()
      assert Organizations.get_organization!(organization.id) == organization
    end

    test "create_organization/1 with valid data creates a organization" do
      valid_attrs = %{name: "some-name"}

      assert {:ok, %Organization{} = organization} =
               Organizations.create_organization(valid_attrs)

      assert organization.name == "some-name"
    end

    test "create_organization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organizations.create_organization(@invalid_attrs)
    end

    test "update_organization/2 with valid data updates the organization" do
      organization = organization_fixture()
      update_attrs = %{name: "some-updated-name"}

      assert {:ok, %Organization{} = organization} =
               Organizations.update_organization(organization, update_attrs)

      assert organization.name == "some-updated-name"
    end

    test "update_organization/2 with invalid data returns error changeset" do
      organization = organization_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Organizations.update_organization(organization, @invalid_attrs)

      assert organization == Organizations.get_organization!(organization.id)
    end

    test "delete_organization/1 deletes the organization" do
      organization = organization_fixture()
      assert {:ok, %Organization{}} = Organizations.delete_organization(organization)
      assert_raise Ecto.NoResultsError, fn -> Organizations.get_organization!(organization.id) end
    end

    test "change_organization/1 returns a organization changeset" do
      organization = organization_fixture()
      assert %Ecto.Changeset{} = Organizations.change_organization(organization)
    end

    test "create_organization_with_user/2 makes the first user an owner" do
      user = user_fixture()
      attrs = %{name: "test-org", github_installation_id: 123_456}

      assert {:ok, %Organization{} = organization} =
               Organizations.create_organization_with_user(user, attrs)

      # Verify organization was created with correct attributes
      assert organization.name == "test-org"
      assert organization.github_installation_id == 123_456

      # Verify user was added as owner
      user_organization =
        Repo.get_by(UserOrganization, user_id: user.id, organization_id: organization.id)

      assert user_organization.role == :owner
    end

    test "ensure_user_in_organization/2 adds user as member to existing organization" do
      # Create first user and organization
      owner_user = user_fixture(%{username: "owner", email: "owner@test.com"})
      attrs = %{name: "existing-org", github_installation_id: 789_012}

      {:ok, organization} = Organizations.create_organization_with_user(owner_user, attrs)

      # Create second user
      member_user = user_fixture(%{username: "member", email: "member@test.com"})

      # Add second user to existing organization
      assert {:ok, %Organization{} = returned_org} =
               Organizations.ensure_user_in_organization(member_user, organization)

      assert returned_org.id == organization.id

      # Verify owner user still has owner role
      owner_user_org =
        Repo.get_by(UserOrganization, user_id: owner_user.id, organization_id: organization.id)

      assert owner_user_org.role == :owner

      # Verify member user has member role
      member_user_org =
        Repo.get_by(UserOrganization, user_id: member_user.id, organization_id: organization.id)

      assert member_user_org.role == :member
    end

    test "get_or_create_organization/3 creates new org with user as owner" do
      user = user_fixture()
      org_name = "new-org"
      github_installation_id = 111_222

      assert {:ok, %Organization{} = organization} =
               Organizations.get_or_create_organization(user, org_name, github_installation_id)

      # Verify organization was created
      assert organization.name == org_name
      assert organization.github_installation_id == github_installation_id

      # Verify user was added as owner
      user_organization =
        Repo.get_by(UserOrganization, user_id: user.id, organization_id: organization.id)

      assert user_organization.role == :owner
    end

    test "get_or_create_organization/3 adds user as member to existing org" do
      # Create first user and organization
      owner_user = user_fixture(%{username: "owner", email: "owner@test.com"})
      org_name = "shared-org"
      github_installation_id = 333_444

      {:ok, organization} =
        Organizations.get_or_create_organization(owner_user, org_name, github_installation_id)

      # Create second user and add them to the same organization
      member_user = user_fixture(%{username: "member", email: "member@test.com"})

      assert {:ok, %Organization{} = returned_org} =
               Organizations.get_or_create_organization(
                 member_user,
                 org_name,
                 github_installation_id
               )

      assert returned_org.id == organization.id

      # Verify owner user still has owner role
      owner_user_org =
        Repo.get_by(UserOrganization, user_id: owner_user.id, organization_id: organization.id)

      assert owner_user_org.role == :owner

      # Verify member user has member role
      member_user_org =
        Repo.get_by(UserOrganization, user_id: member_user.id, organization_id: organization.id)

      assert member_user_org.role == :member
    end

    test "create_organization_with_user/2 returns error changeset if attrs are invalid" do
      user = user_fixture()
      invalid_attrs = %{name: nil, github_installation_id: nil}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Organizations.create_organization_with_user(user, invalid_attrs)

      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_organization_with_user/2 does not create user_organization if org creation fails" do
      user = user_fixture()
      invalid_attrs = %{name: nil, github_installation_id: nil}

      assert {:error, %Ecto.Changeset{}} =
               Organizations.create_organization_with_user(user, invalid_attrs)

      # There should be no organizations or user_organizations created
      assert Repo.all(Organizations.Organization) == []
      assert Repo.all(UserOrganization) == []
    end
  end
end
