defmodule Swarm.AccountsTest do
  use Swarm.DataCase

  alias Swarm.Accounts
  import Swarm.AccountsFixtures

  describe "users" do
    alias Swarm.Accounts.User

    @invalid_attrs %{
      email: "1234"
    }

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{email: "test@test.com", username: "User", role: "user"}

      assert {:ok, %User{}} = Accounts.create_user(valid_attrs)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{username: "UpdatedUser"}

      assert {:ok, %User{}} = Accounts.update_user(user, update_attrs)
      assert Accounts.get_user!(user.id).username == "UpdatedUser"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "tokens" do
    alias Swarm.Accounts.User

    test "save_token/2 saves a new token to a user WITH expires_in seconds input" do
      user = user_fixture()

      {:ok, new_token} =
        Accounts.save_token(user, %{
          expires_in: 300,
          token: "test",
          context: :github,
          type: :refresh
        })

      assert new_token.token == "test"
      assert new_token.type == :refresh
      assert new_token.context == :github
      assert DateTime.after?(new_token.expires, DateTime.utc_now())
    end

    test "save_token/2 saves a new token to a user WITHOUT expires_in seconds input" do
      user = user_fixture()

      {:ok, new_token} =
        Accounts.save_token(user, %{
          expires: DateTime.add(DateTime.utc_now(), 100, :second),
          token: "test",
          context: :github,
          type: :refresh
        })

      assert new_token.token == "test"
      assert new_token.type == :refresh
      assert new_token.context == :github
      assert DateTime.after?(new_token.expires, DateTime.utc_now())
    end

    test "get_tokens/1 gets tokens for a user" do
      user = user_fixture()

      {:ok, _} =
        Accounts.save_token(user, %{
          expires_in: 300,
          token: "test",
          context: :github,
          type: :access
        })

      {:ok, _} =
        Accounts.save_token(user, %{
          expires_in: 20,
          token: "test2",
          context: :github,
          type: :refresh
        })

      [new_token, new_token2] = Accounts.get_tokens(user)

      assert Accounts.get_user!(user.id) == user
      assert new_token.token == "test"
      assert new_token.type == :access
      assert new_token.context == :github
      assert DateTime.after?(new_token.expires, DateTime.utc_now())
      assert new_token2.token == "test2"
      assert new_token2.type == :refresh
      assert new_token2.context == :github
      assert DateTime.after?(new_token2.expires, DateTime.utc_now())
    end
  end
end
