defmodule Swarm.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Swarm.Repo

  alias Swarm.Accounts.User
  alias Swarm.Accounts.Token

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a single user by username.

  Returns `nil` if the User does not exist.
  """
  def get_user_by_username(username), do: Repo.get_by(User, username: username)

  @doc """
  Gets a single user by username and email or creates a new user if they don't exist.

  Returns the existing user if they exist, or a new user if they don't.
  """
  def get_or_create_user(email, username) do
    case get_user_by_username(username) do
      nil -> create_user(%{email: email, username: username, role: "user"})
      user -> {:ok, user}
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Saves a token for a user.

  Can include integer `expires_in` attribute that can be converted to a DateTime for `:expires`.

  ## Examples

      iex> save_token(user, %{field: new_value})
      {:ok, %Token{}}

      iex> save_token(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def save_token(%User{} = user, attrs \\ %{}) do
    attrs =
      case Map.get(attrs, :expires_in) do
        nil ->
          attrs

        expires_in ->
          expires = DateTime.add(DateTime.utc_now(), expires_in, :second)

          Map.put(attrs, :expires, expires)
      end

    Token
    |> where(user_id: ^user.id)
    |> where(type: ^Map.get(attrs, :type))
    |> where(context: ^Map.get(attrs, :context))
    |> Repo.delete_all()

    %Token{}
    |> Token.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Gets tokens for a user.

  ## Examples

      iex> get_tokens(user)
      [%Token{}, ...]

  """
  def get_tokens(%User{} = user) do
    Token
    |> where(user_id: ^user.id)
    |> Repo.all()
  end

  @doc """
  Gets tokens for a user of a specific type and context.

  ## Examples

      iex> get_token(user, :access, :github)
      %Token{}

      iex> get_token(user, :refresh, :github)
      nil

  """
  def get_token(%User{} = user, type, context) do
    Token
    |> where(user_id: ^user.id)
    |> where(type: ^type)
    |> where(context: ^context)
    |> Repo.one()
  end

  @doc """
  Deletes a token for a user of a specific type and context.

  ## Examples

      iex> get_token(user)
      [%Token{}, ...]

  """
  def delete_token(%User{} = user, type, context) do
    Token
    |> where(user_id: ^user.id)
    |> where(type: ^type)
    |> where(context: ^context)
    |> Repo.delete_all()
  end
end
