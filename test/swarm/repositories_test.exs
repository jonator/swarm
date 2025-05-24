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

      assert Repositories.get_repository!(repository.id) ==
               Ecto.reset_fields(repository, [:users])
    end

    test "create_repository/1 with valid data creates a repository" do
      valid_attrs = %{external_id: "github:123456", name: "name", owner: "some_owner"}

      assert {:ok, %Repository{} = repository} = Repositories.create_repository(valid_attrs)
      assert repository.external_id == "github:123456"
      assert repository.name == "name"
      assert repository.owner == "some_owner"
    end

    test "create_repository/1 with valid data including project creates a repository & project" do
      valid_attrs = %{
        external_id: "github:789012",
        name: "name",
        owner: "some_owner",
        projects: [%{type: "nextjs", root_dir: "path"}]
      }

      assert {:ok, %Repository{} = repository} = Repositories.create_repository(valid_attrs)
      assert repository.external_id == "github:789012"
      assert repository.name == "name"
      assert repository.owner == "some_owner"
    end

    test "create_repository/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Repositories.create_repository(@invalid_attrs)
    end

    test "create_repositories/2 with valid data creates a list of repositories for some user" do
      user = Swarm.AccountsFixtures.user_fixture()

      valid_attrs = [
        %{external_id: "github:123456", name: "name", owner: "some_owner"},
        %{external_id: "github:789012", name: "name", owner: "some_owner"}
      ]

      assert {:ok, [%Repository{}, %Repository{}]} =
               Repositories.create_repositories(user, valid_attrs)
    end

    test "create_repositories/2 updates existing repository with new name and owner" do
      user = Swarm.AccountsFixtures.user_fixture()

      initial_attrs = [
        %{external_id: "github:123456", name: "initial_name", owner: "initial_owner"}
      ]

      {:ok, [initial_repo]} = Repositories.create_repositories(user, initial_attrs)

      update_attrs = [
        %{external_id: "github:123456", name: "updated_name", owner: "updated_owner"}
      ]

      {:ok, [updated_repo]} = Repositories.create_repositories(user, update_attrs)

      assert updated_repo.id == initial_repo.id
      assert updated_repo.external_id == "github:123456"
      assert updated_repo.name == "updated_name"
      assert updated_repo.owner == "updated_owner"
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

      assert Ecto.reset_fields(repository, [:users]) ==
               Repositories.get_repository!(repository.id)
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

      assert Repositories.get_repository_by_external_id!("github:555777") ==
               Ecto.reset_fields(repository, [:users])
    end

    test "get_repository_by_external_id!/1 raises error when repository doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Repositories.get_repository_by_external_id!("github:nonexistent")
      end
    end

    test "get_repository_by_external_id/1 returns the repository with given external_id" do
      user = Swarm.AccountsFixtures.user_fixture()
      repository = repository_fixture(user, %{external_id: "github:444333"})

      assert Repositories.get_repository_by_external_id("github:444333") ==
               Ecto.reset_fields(repository, [:users])
    end

    test "get_repository_by_external_id/1 returns nil when repository doesn't exist" do
      assert Repositories.get_repository_by_external_id("github:nonexistent") == nil
    end

    test "validates external_id format" do
      user = Swarm.AccountsFixtures.user_fixture(%{username: "testuser"})

      # Should fail if we try to create with invalid format manually
      assert {:error, %Ecto.Changeset{}} =
               Repositories.create_repository(user, %{
                 external_id: "invalid-format",
                 name: "test",
                 owner: "testuser"
               })
    end

    test "enforces unique constraint on external_id" do
      # Create first repository
      attrs = %{external_id: "github:123456", name: "repo_name", owner: "owner_name"}
      assert {:ok, %Repository{}} = Repositories.create_repository(attrs)

      # Try to create another repository with same external_id (should fail)
      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(%{
                 external_id: "github:123456",
                 name: "different_name",
                 owner: "different_owner"
               })

      assert [
               external_id:
                 {_, [constraint: :unique, constraint_name: "repositories_external_id_index"]}
             ] = changeset.errors

      # Different external_id should work even with same name and owner
      assert {:ok, %Repository{}} =
               Repositories.create_repository(%{
                 external_id: "github:654321",
                 name: "repo_name",
                 owner: "owner_name"
               })
    end

    test "validates name length" do
      # Name too short (less than 3 characters)
      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(%{
                 external_id: "github:123456",
                 name: "ab",
                 owner: "owner"
               })

      assert {:name,
              {"should be at least %{count} character(s)",
               [count: 3, validation: :length, kind: :min, type: :string]}} in changeset.errors

      # Name too long (more than 100 characters)
      long_name = String.duplicate("a", 101)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(%{
                 external_id: "github:123457",
                 name: long_name,
                 owner: "owner"
               })

      assert {:name,
              {"should be at most %{count} character(s)",
               [count: 100, validation: :length, kind: :max, type: :string]}} in changeset.errors
    end

    test "validates name format" do
      # Invalid characters in name
      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(%{
                 external_id: "github:123458",
                 name: "invalid@name",
                 owner: "owner"
               })

      assert {:name,
              {"can only contain letters, numbers, spaces, underscores, hyphens, slashes, and periods",
               [validation: :format]}} in changeset.errors

      # Valid name with allowed characters
      assert {:ok, %Repository{}} =
               Repositories.create_repository(%{
                 external_id: "github:123459",
                 name: "valid-name_123 /repo.test",
                 owner: "owner"
               })
    end

    test "validates name exclusion (reserved names)" do
      # Test each reserved name
      reserved_names = ["admin", "system", "root"]

      for {reserved_name, index} <- Enum.with_index(reserved_names) do
        assert {:error, %Ecto.Changeset{} = changeset} =
                 Repositories.create_repository(%{
                   external_id: "github:#{123_460 + index}",
                   name: reserved_name,
                   owner: "owner"
                 })

        assert {:name,
                {"is reserved", [validation: :exclusion, enum: ["admin", "system", "root"]]}} in changeset.errors
      end
    end

    test "trims whitespace from name" do
      assert {:ok, %Repository{} = repository} =
               Repositories.create_repository(%{
                 external_id: "github:123463",
                 name: "  trimmed_name  ",
                 owner: "owner"
               })

      assert repository.name == "trimmed_name"
    end
  end
end
