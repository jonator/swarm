defmodule Swarm.RepositoriesTest do
  use Swarm.DataCase

  alias Swarm.Repositories

  describe "repositories" do
    alias Swarm.Repositories.Repository

    import Swarm.RepositoriesFixtures

    @invalid_attrs %{external_id: nil, name: nil, owner: nil}

    test "list_repositories/0 returns all repositories" do
      repository = repository_fixture()
      assert Repositories.list_repositories() == [Ecto.reset_fields(repository, [:users])]
    end

    test "get_repository!/1 returns the repository with given id" do
      repository = repository_fixture()
      assert Repositories.get_repository!(repository.id) == Ecto.reset_fields(repository, [:users])
    end

    test "create_repository/1 with valid data creates a repository" do
      valid_attrs = %{external_id: "github:123456", name: "name", owner: "some_owner"}

      assert {:ok, %Repository{} = repository} = Repositories.create_repository(valid_attrs)
      assert repository.external_id == "github:123456"
      assert repository.name == "name"
      assert repository.owner == "some_owner"
    end

    test "create_repository/1 with valid data including project creates a repository & project" do
      valid_attrs = %{external_id: "github:789012", name: "name", owner: "some_owner", projects: [%{type: "nextjs", root_dir: "path"}]}

      assert {:ok, %Repository{} = repository} = Repositories.create_repository(valid_attrs)
      assert repository.external_id == "github:789012"
      assert repository.name == "name"
      assert repository.owner == "some_owner"
    end

    test "create_repository/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Repositories.create_repository(@invalid_attrs)
    end

    test "update_repository/2 with valid data updates the repository" do
      repository = repository_fixture()
      update_attrs = %{external_id: "github:999888", name: "updated_name", owner: "updated_owner"}

      assert {:ok, %Repository{} = repository} =
               Repositories.update_repository(repository, update_attrs)

      assert repository.external_id == "github:999888"
      assert repository.name == "updated_name"
      assert repository.owner == "updated_owner"
    end

    test "update_repository/2 with invalid data returns error changeset" do
      repository = repository_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Repositories.update_repository(repository, @invalid_attrs)

      assert Ecto.reset_fields(repository, [:users]) == Repositories.get_repository!(repository.id)
    end

    test "delete_repository/1 deletes the repository" do
      repository = repository_fixture()
      assert {:ok, %Repository{}} = Repositories.delete_repository(repository)
      assert_raise Ecto.NoResultsError, fn -> Repositories.get_repository!(repository.id) end
    end

    test "change_repository/1 returns a repository changeset" do
      repository = repository_fixture()
      assert %Ecto.Changeset{} = Repositories.change_repository(repository)
    end

    test "get_repository_by_external_id!/1 returns the repository with given external_id" do
      user = Swarm.AccountsFixtures.user_fixture()
      repository = repository_fixture(user, %{external_id: "github:555777"})
      assert Repositories.get_repository_by_external_id!("github:555777") == Ecto.reset_fields(repository, [:users])
    end

    test "get_repository_by_external_id!/1 raises error when repository doesn't exist" do
      assert_raise Ecto.NoResultsError, fn -> 
        Repositories.get_repository_by_external_id!("github:nonexistent")
      end
    end

    test "get_repository_by_external_id/1 returns the repository with given external_id" do
      user = Swarm.AccountsFixtures.user_fixture()
      repository = repository_fixture(user, %{external_id: "github:444333"})
      assert Repositories.get_repository_by_external_id("github:444333") == Ecto.reset_fields(repository, [:users])
    end

    test "get_repository_by_external_id/1 returns nil when repository doesn't exist" do
      assert Repositories.get_repository_by_external_id("github:nonexistent") == nil
    end

    test "validates external_id format" do
      user = Swarm.AccountsFixtures.user_fixture(%{username: "testuser"})
      
      # Should fail if we try to create with invalid format manually
      assert {:error, %Ecto.Changeset{}} = 
        Repositories.create_repository(user, %{external_id: "invalid-format", name: "test", owner: "testuser"})
    end
  end
end
