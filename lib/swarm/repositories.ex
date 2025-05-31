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
  Gets a single repository for a user by repository ID or external ID.

  This function ensures the user has access to the repository.

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
  Creates a list of repositories for a given user.
  If a repository already exists, it will be updated with the appropriate new values.

  ## Examples

      iex> create_repositories(user, [%{field: value}, %{field: value}])
      {:ok, [%Repository{}, ...]}

  """
  def create_repositories(user, attrs_list) when is_list(attrs_list) do
    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    attrs_list_timestamped =
      Enum.map(attrs_list, fn attrs ->
        Map.put(attrs, :inserted_at, timestamp) |> Map.put(:updated_at, timestamp)
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
    # Postgres does not support RETURNING in INSERT
    |> Ecto.Multi.run(:associate_user, fn repo, %{insert_repositories: {_count, nil}} ->
      new_repositories =
        Repo.all(
          from r in Repository,
            where:
              fragment(
                "(name, owner) IN (SELECT * FROM unnest(?::text[], ?::text[]))",
                ^Enum.map(attrs_list, & &1.name),
                ^Enum.map(attrs_list, & &1.owner)
              )
        )

      user
      |> Repo.preload(:repositories)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:repositories, new_repositories)
      |> repo.update()
      |> case do
        {:ok, %User{}} -> {:ok, new_repositories}
        {:error, _} = error -> error
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{associate_user: repositories}} -> {:ok, repositories}
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
  def update_repository(user, id, attrs) do
    user
    |> Repo.preload(:repositories)
    |> Map.get(:repositories)
    |> Enum.find(&(&1.id == String.to_integer(id)))
    |> case do
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
