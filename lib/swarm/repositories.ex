defmodule Swarm.Repositories do
  @moduledoc """
  The Repositories context.
  """

  import Ecto.Query, warn: false
  alias Swarm.Repo

  alias Swarm.Accounts.User
  alias Swarm.Organizations.Organization
  alias Swarm.Repositories.Repository
  alias Swarm.Projects.Project

  @doc """
  Returns the list of repositories.

  When called with a User, returns the list of repositories for the user through their organizations.
  When called with an Organization, returns the list of repositories for that organization.
  When called with no arguments, returns all repositories.

  ## Examples

      iex> list_repositories()
      [%Repository{}, ...]

      iex> list_repositories(user)
      [%Repository{}, ...]

      iex> list_repositories(organization)
      [%Repository{}, ...]

  """
  def list_repositories do
    Repo.all(Repository)
    |> Repo.preload(:organization)
  end

  def list_repositories(%User{} = user) do
    user_organization_ids =
      user
      |> Repo.preload(:organizations)
      |> Map.get(:organizations)
      |> Enum.map(& &1.id)

    Repo.all(
      from r in Repository,
        where: r.organization_id in ^user_organization_ids
    )
    |> Repo.preload(:organization)
  end

  def list_repositories(%Organization{} = organization) do
    Repo.preload(organization, :repositories).repositories
  end

  @doc """
  Gets a single repository.

  Raises `Ecto.NoResultsError` if the Repository does not exist.

  ## Examples

      iex> get_repository!(123)
      %Repository{}

      iex> get_repository!(456)
      ** (Ecto.NoResultsError)

  """
  def get_repository!(id) do
    Repo.get!(Repository, id)
    |> Repo.preload(:organization)
  end

  @doc """
  Gets a single repository by external_id.

  Returns the repository if found, otherwise returns nil.

  ## Examples

      iex> get_repository_by_external_id("github:123456")
      %Repository{}

      iex> get_repository_by_external_id("nonexistent")
      nil

  """
  def get_repository_by_external_id(external_id) do
    Repo.get_by(Repository, external_id: external_id)
    |> case do
      nil -> nil
      repository -> Repo.preload(repository, :organization)
    end
  end

  @doc """
  Gets a single repository by external_id.

  Raises `Ecto.NoResultsError` if the Repository does not exist.

  ## Examples

      iex> get_repository_by_external_id!("github:123456")
      %Repository{}

      iex> get_repository_by_external_id!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  def get_repository_by_external_id!(external_id) do
    Repo.get_by!(Repository, external_id: external_id)
    |> Repo.preload(:organization)
  end

  @doc """
  Gets a single repository for a user by repository ID or external ID.

  This function ensures the user has access to the repository through their organizations.

  ## Examples

      iex> get_user_repository(user, "123")
      %Repository{}

      iex> get_user_repository(user, "github:123456")
      %Repository{}

      iex> get_user_repository(user, "nonexistent")
      nil

  """
  def get_user_repository(%User{} = user, repository_identifier) do
    user_repositories = list_repositories(user)

    # Try to find by ID first (if it's a numeric string)
    case Integer.parse(repository_identifier) do
      {id, ""} ->
        Enum.find(user_repositories, &(&1.id == id))

      _ ->
        # Try to find by external_id
        Enum.find(user_repositories, &(&1.external_id == repository_identifier))
    end
  end

  @doc """
  Creates a repository.

  ## Examples

      iex> create_repository(%{field: value})
      {:ok, %Repository{}}

      iex> create_repository(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_repository(attrs) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a repository for a given user through their personal organization if
  provided a user, or a repository for a given organization if provided an
  organization.

  ## Examples

      iex> create_repository(user, %{field: value})
      {:ok, %Repository{}}

      iex> create_repository(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_repository(organization, %{field: value})
      {:ok, %Repository{}}

      iex> create_repository(organization, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_repository(%User{username: username} = user, attrs) do
    # Get the user's personal organization (first organization they own)
    user_organizations = Swarm.Organizations.list_organizations(user)

    case Enum.find(user_organizations, &(&1.name == username)) do
      nil ->
        {:error, "User does not have a personal organization"}

      organization ->
        create_repository(organization, attrs)
    end
  end

  def create_repository(%Organization{} = organization, attrs) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:organization, organization)
    |> Ecto.Changeset.cast_assoc(:projects, with: &Project.changeset/2)
    |> Repo.insert()
  end

  @doc """
  Creates a list of repositories for a given user through their personal organization.
  If a repository already exists, it will be updated with the appropriate new values.

  If provided an organization, creates a list of repositories for that organization.
  If a repository already exists, it will be updated with the appropriate new values.

  ## Examples

      iex> create_repositories(user, [%{field: value}, %{field: value}])
      {:ok, [%Repository{}, ...]}

      iex> create_repositories(organization, [%{field: value}, %{field: value}])
      {:ok, [%Repository{}, ...]}

  """
  def create_repositories(%User{username: username} = user, attrs_list)
      when is_list(attrs_list) do
    # Get the user's personal organization
    user_organizations = Swarm.Organizations.list_organizations(user)

    case Enum.find(user_organizations, &(&1.name == username)) do
      nil ->
        {:error, "User does not have a personal organization"}

      organization ->
        create_repositories(organization, attrs_list)
    end
  end

  def create_repositories(%Organization{} = organization, attrs_list)
      when is_list(attrs_list) do
    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    attrs_list_timestamped =
      Enum.map(attrs_list, fn attrs ->
        attrs
        |> Map.put(:organization_id, organization.id)
        |> Map.put(:inserted_at, timestamp)
        |> Map.put(:updated_at, timestamp)
      end)

    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:insert_repositories, Repository, attrs_list_timestamped,
      conflict_target: [:external_id],
      on_conflict: {:replace, [:name, :owner, :linear_team_external_ids, :updated_at]}
    )
    |> Ecto.Multi.run(:check_insert_count, fn
      _repo, %{insert_repositories: {count, _}} ->
        if count == length(attrs_list) do
          {:ok, nil}
        else
          {:error,
           {:failed_insert,
            "Expected to insert #{length(attrs_list)} repositories but inserted #{count}"}}
        end
    end)
    |> Ecto.Multi.run(:get_repositories, fn _repo, %{insert_repositories: {_count, nil}} ->
      new_repositories =
        Repo.all(
          from r in Repository,
            where:
              r.organization_id == ^organization.id and
                fragment(
                  "(name, owner) IN (SELECT * FROM unnest(?::text[], ?::text[]))",
                  ^Enum.map(attrs_list, & &1.name),
                  ^Enum.map(attrs_list, & &1.owner)
                )
        )

      {:ok, new_repositories}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{get_repositories: repositories}} -> {:ok, repositories}
      {:error, _failed_operation, _failed_value, _changes_so_far} = error -> error
    end
  end

  @doc """
  Updates a repository for a given user. Returns the updated repository if found, otherwise returns {:error, :not_found}.

  ## Examples

      iex> update_repository(repository, %{field: new_value})
      {:ok, %Repository{}}

      iex> update_repository(repository, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_repository(%User{} = user, id, attrs) do
    user_repositories = list_repositories(user)

    case Enum.find(user_repositories, &(&1.id == String.to_integer(id))) do
      nil -> {:error, :not_found}
      repository -> update_repository(repository, attrs)
    end
  end

  @doc """
  Updates a repository.

  ## Examples

      iex> update_repository(repository, %{field: new_value})
      {:ok, %Repository{}}

      iex> update_repository(repository, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_repository(%Repository{} = repository, attrs) do
    repository
    |> Repository.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a repository.

  ## Examples

      iex> delete_repository(repository)
      {:ok, %Repository{}}

      iex> delete_repository(repository)
      {:error, %Ecto.Changeset{}}

  """
  def delete_repository(%Repository{} = repository) do
    Repo.delete(repository)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking repository changes.

  ## Examples

      iex> change_repository(repository)
      %Ecto.Changeset{data: %Repository{}}

  """
  def change_repository(%Repository{} = repository, attrs \\ %{}) do
    Repository.changeset(repository, attrs)
  end
end
