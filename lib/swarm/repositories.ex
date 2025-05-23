defmodule Swarm.Repositories do
  @moduledoc """
  The Repositories context.
  """

  import Ecto.Query, warn: false
  alias Swarm.Repo

  alias Swarm.Accounts.User
  alias Swarm.Repositories.Repository
  alias Swarm.Projects.Project

  @doc """
  Returns the list of repositories.

  ## Examples

      iex> list_repositories()
      [%Repository{}, ...]

  """
  def list_repositories do
    Repo.all(Repository)
  end

  @doc """
  Returns the list of repositories for a given user.

  ## Examples

      iex> list_repositories(user)
      [%Repository{}, ...]

  """
  def list_repositories(%User{} = user) do
    Repo.preload(user, :repositories).repositories
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
  def get_repository!(id), do: Repo.get!(Repository, id)

  @doc """
  Gets a single repository by external_id.

  Raises `Ecto.NoResultsError` if the Repository does not exist.

  ## Examples

      iex> get_repository_by_external_id!("github:123456")
      %Repository{}

      iex> get_repository_by_external_id!("github:999999")
      ** (Ecto.NoResultsError)

  """
  def get_repository_by_external_id!(external_id) do
    Repo.get_by!(Repository, external_id: external_id)
  end

  @doc """
  Gets a single repository by external_id.

  Returns `nil` if the Repository does not exist.

  ## Examples

      iex> get_repository_by_external_id("github:123456")
      %Repository{}

      iex> get_repository_by_external_id("github:999999")
      nil

  """
  def get_repository_by_external_id(external_id) do
    Repo.get_by(Repository, external_id: external_id)
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
  Creates a repository for a given user (not org).

  ## Examples

      iex> create_repository(user, %{field: value})
      {:ok, %Repository{}}

      iex> create_repository(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_repository(%User{username: username} = user, attrs) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:users, [user])
    |> Ecto.Changeset.validate_change(:owner, fn :owner, owner ->
      if owner == username do
        []
      else
        [owner: "must be the same as the user"]
      end
    end)
    |> Ecto.Changeset.cast_assoc(:projects, with: &Project.changeset/2)
    |> Repo.insert()
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
