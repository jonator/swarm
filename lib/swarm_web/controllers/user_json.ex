defmodule SwarmWeb.UserJSON do
  alias Swarm.Accounts.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{users: for(user <- users, do: user(user))}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{user: user(user)}
  end

  defp user(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      username: user.username,
      role: user.role,
      avatar_url: user.avatar_url,
      created_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
