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

      new_token = Accounts.get_token(user, :access, :github)
      new_token2 = Accounts.get_token(user, :refresh, :github)

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

    test "delete_token/3 deletes the specified token for a user" do
      user = user_fixture()

      {:ok, token} =
        Accounts.save_token(user, %{
          expires_in: 300,
          token: "test",
          context: :github,
          type: :access
        })

      assert token.id == Accounts.get_token(user, :access, :github).id

      Accounts.delete_token(user, :access, :github)
      assert nil == Accounts.get_token(user, :access, :github)
    end

    test "save_token/2 deletes previous tokens for the same user, context, and type" do
      user = user_fixture(%{email: "tes1t@test.com", username: "User1"})
      other_user = user_fixture(%{email: "test2@test.com", username: "User2"})

      # Create initial tokens
      {:ok, initial_token} =
        Accounts.save_token(user, %{
          expires_in: 300,
          token: "initial",
          context: :github,
          type: :access
        })

      # Create a token for another user (should not be affected)
      {:ok, other_user_token} =
        Accounts.save_token(other_user, %{
          expires_in: 300,
          token: "other_user",
          context: :github,
          type: :access
        })

      # Create a token with different type (should not be affected)
      {:ok, different_type_token} =
        Accounts.save_token(user, %{
          expires_in: 300,
          token: "different_type",
          context: :github,
          type: :refresh
        })

      # Save a new token that should replace initial_token
      {:ok, new_token} =
        Accounts.save_token(user, %{
          expires_in: 300,
          token: "new",
          context: :github,
          type: :access
        })

      tokens = Accounts.get_tokens(user)
      other_user_tokens = Accounts.get_tokens(other_user)

      # Initial token should be deleted
      refute Enum.any?(tokens, fn t -> t.id == initial_token.id end)
      # New token should exist
      assert Enum.any?(tokens, fn t -> t.id == new_token.id end)
      # Different type token should still exist
      assert Enum.any?(tokens, fn t -> t.id == different_type_token.id end)
      # Other user's token should still exist
      assert Enum.any?(other_user_tokens, fn t -> t.id == other_user_token.id end)
    end
  end
end
