defmodule Swarm.Organizations do
  @moduledoc """
  The Organizations context.
  """

  import Ecto.Query, warn: false
  alias Swarm.Repo

  alias Swarm.Organizations.Organization
  alias Swarm.Accounts
  alias Swarm.Accounts.User
  alias Swarm.Accounts.UserOrganization

  @doc """
  Returns the list of organizations.

  ## Examples

      iex> list_organizations()
      [%Organization{}, ...]

  """
  def list_organizations do
    Repo.all(Organization)
  end

  @doc """
  Returns the list of organizations for a given user.

  ## Examples

      iex> list_organizations(user)
      [%Organization{}, ...]

  """
  def list_organizations(%User{} = user) do
    Repo.preload(user, :organizations).organizations
  end

  @doc """
  Gets a single organization.

  Raises `Ecto.NoResultsError` if the Organization does not exist.

  ## Examples

      iex> get_organization!(123)
      %Organization{}

      iex> get_organization!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Gets a user by ID if they share an organization with the given user.
  Includes the same user if they are a member of the organization.

  Returns `nil` if the user doesn't exist or doesn't share any organizations.

  ## Examples

      iex> get_shared_user(user, 123)
      %User{}

      iex> get_shared_user(user, 456)
      nil

  """
  def get_shared_user(%User{} = user, shared_user_id) do
    if user.id == shared_user_id do
      user
    else
      user_org_ids =
        user
        |> Repo.preload(:organizations)
        |> Map.get(:organizations)
        |> Enum.map(& &1.id)

      case Accounts.get_user(shared_user_id) do
        nil ->
          nil

        shared_user ->
          shared_user_org_ids =
            shared_user
            |> Repo.preload(:organizations)
            |> Map.get(:organizations)
            |> Enum.map(& &1.id)

          if Enum.any?(user_org_ids, fn org_id -> org_id in shared_user_org_ids end) do
            shared_user
          else
            nil
          end
      end
    end
  end

  @doc """
  Gets an organization by GitHub installation ID.

  ## Examples

      iex> get_organization_by_github_installation_id(123456)
      %Organization{}

      iex> get_organization_by_github_installation_id(999999)
      nil

  """
  def get_organization_by_github_installation_id(github_installation_id) do
    Repo.get_by(Organization, github_installation_id: github_installation_id)
  end

  @doc """
  Gets or creates an organization for a user with the given GitHub installation ID and organization name.

  If the organization doesn't exist, it creates a new one with the provided name and makes the user the owner.
  If the organization exists but the user is not a member, it adds the user as a member.
  If the organization exists and the user is already a member, it returns the existing organization.

  ## Examples

      iex> get_or_create_organization(user, "my-org", 123456)
      {:ok, %Organization{}}

  """
  def get_or_create_organization(%User{} = user, org_name, github_installation_id) do
    case get_organization_by_github_installation_id(github_installation_id) do
      nil ->
        create_organization_with_user(user, %{
          name: org_name,
          github_installation_id: github_installation_id
        })

      organization ->
        ensure_user_in_organization(user, organization)
    end
  end

  @doc """
  Gets or creates a personal organization for a user with the given GitHub installation ID.

  ## Examples

      iex> get_or_create_personal_organization(user, 123456)
      {:ok, %Organization{}}

  """
  def get_or_create_personal_organization(%User{} = user, github_installation_id) do
    get_or_create_organization(user, user.username, github_installation_id)
  end

  @doc """
  Ensures a user is a member of an organization. If the user is not already a member,
  adds them as a member. If they are already a member, returns the organization.

  ## Examples

      iex> ensure_user_in_organization(user, organization)
      {:ok, %Organization{}}

  """
  def ensure_user_in_organization(%User{} = user, %Organization{} = organization) do
    # Check if user is already a member
    existing_membership =
      Repo.get_by(UserOrganization, user_id: user.id, organization_id: organization.id)

    case existing_membership do
      nil ->
        # User is not a member, add them as a member
        %UserOrganization{}
        |> UserOrganization.changeset(%{role: :member})
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:organization, organization)
        |> Repo.insert()
        |> case do
          {:ok, _user_organization} -> {:ok, organization}
          {:error, changeset} -> {:error, changeset}
        end

      _membership ->
        # User is already a member
        {:ok, organization}
    end
  end

  @doc """
  Creates an organization with a user.

  If this is the first user in the organization, they become the owner.
  The organization is created with the provided attributes.

  ## Examples

      iex> create_organization_with_user(user, %{name: "my-org", github_installation_id: 123456})
      {:ok, %Organization{}}

      iex> create_organization_with_user(user, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization_with_user(%User{} = user, attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:organization, Organization.changeset(%Organization{}, attrs))
    |> Ecto.Multi.insert(:user_organization, fn %{organization: organization} ->
      %UserOrganization{}
      |> UserOrganization.changeset(%{role: :owner})
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Ecto.Changeset.put_assoc(:organization, organization)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{organization: organization}} -> {:ok, organization}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  @doc """
  Creates a organization.

  ## Examples

      iex> create_organization(%{field: value})
      {:ok, %Organization{}}

      iex> create_organization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization(attrs \\ %{}) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a organization.

  ## Examples

      iex> update_organization(organization, %{field: new_value})
      {:ok, %Organization{}}

      iex> update_organization(organization, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a organization.

  ## Examples

      iex> delete_organization(organization)
      {:ok, %Organization{}}

      iex> delete_organization(organization)
      {:error, %Ecto.Changeset{}}

  """
  def delete_organization(%Organization{} = organization) do
    Repo.delete(organization)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization changes.

  ## Examples

      iex> change_organization(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end
end
