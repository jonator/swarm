defmodule Swarm.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{email: "test@test.com", username: "User", avatar_url: "https://example.com/avatar.jpg", role: "user"}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{})
      |> Swarm.Accounts.create_user()

    user
  end
end
