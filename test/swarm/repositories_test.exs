defmodule Swarm.RepositoriesTest do
  use Swarm.DataCase

  alias Swarm.Repositories
  alias Swarm.Organizations

  describe "repositories" do
    alias Swarm.Repositories.Repository

    import Swarm.RepositoriesFixtures
    import Swarm.OrganizationsFixtures

    @invalid_attrs %{external_id: nil, name: nil, owner: nil}

    test "list_repositories/0 returns all repositories" do
      repository = repository_fixture()
      assert Repositories.list_repositories() == [repository]
    end

    test "list_repositories/2 with no params returns all user repositories" do
      user = Swarm.AccountsFixtures.user_fixture()
      repository1 = repository_fixture(user, %{owner: user.username})
      repository2 = repository_fixture(user, %{owner: user.username})
      {:ok, other_org} = Organizations.get_or_create_organization(user, "other_org", 123_456)
      repository3 = repository_fixture(other_org, %{owner: other_org.name})

      repositories = Repositories.list_repositories(user, %{})
      assert length(repositories) == 3
      assert repository1 in repositories
      assert repository2 in repositories
      assert repository3 in repositories
    end

    test "list_repositories/2 with owner param matching user username returns user repositories" do
      user = Swarm.AccountsFixtures.user_fixture()
      repository1 = repository_fixture(user, %{owner: user.username})
      repository2 = repository_fixture(user, %{owner: user.username})
      {:ok, other_org} = Organizations.get_or_create_organization(user, "other_org", 123_456)
      repository3 = repository_fixture(other_org, %{owner: other_org.name})

      repositories = Repositories.list_repositories(user, %{"owner" => user.username})
      assert length(repositories) == 2
      assert repository1 in repositories
      assert repository2 in repositories
      assert repository3 not in repositories
    end

    test "list_repositories/2 with owner param for different owner returns only that owner's repositories" do
      user = Swarm.AccountsFixtures.user_fixture()
      repository1 = repository_fixture(user, %{owner: user.username})
      repository2 = repository_fixture(user, %{owner: user.username})
      {:ok, other_org} = Organizations.get_or_create_organization(user, "other_org", 123_456)
      repository3 = repository_fixture(other_org, %{owner: other_org.name})

      repositories = Repositories.list_repositories(user, %{"owner" => "other_org"})
      assert length(repositories) == 1
      assert repository3 in repositories
      assert repository1 not in repositories
      assert repository2 not in repositories
    end

    test "list_repositories/2 with empty owner param returns all user repositories" do
      user = Swarm.AccountsFixtures.user_fixture()
      repository1 = repository_fixture(user, %{owner: user.username})
      repository2 = repository_fixture(user, %{owner: user.username})
      {:ok, other_org} = Organizations.get_or_create_organization(user, "other_org", 123_456)
      repository3 = repository_fixture(other_org, %{owner: other_org.name})

      repositories = Repositories.list_repositories(user, %{"owner" => ""})
      assert length(repositories) == 3
      assert repository1 in repositories
      assert repository2 in repositories
      assert repository3 in repositories
    end

    test "list_repositories/2 with user and nil params returns all user repositories" do
      user = Swarm.AccountsFixtures.user_fixture()
      repository1 = repository_fixture(user)
      repository2 = repository_fixture(user)

      repositories = Repositories.list_repositories(user)
      assert length(repositories) == 2
      assert repository1 in repositories
      assert repository2 in repositories
    end

    test "get_repository!/1 returns the repository with given id" do
      repository = repository_fixture()

      assert Repositories.get_repository!(repository.id) == repository
    end

    test "create_repository/1 with valid data creates a repository" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)
      valid_attrs = %{external_id: "github:123456", name: "name", owner: user.username}

      assert {:ok, %Repository{} = repository} = Repositories.create_repository(user, valid_attrs)
      assert repository.external_id == "github:123456"
      assert repository.name == "name"
      assert repository.owner == user.username
    end

    test "create_repository/1 with valid data including project creates a repository & project" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)

      valid_attrs = %{
        external_id: "github:789012",
        name: "name",
        owner: "user",
        projects: [%{type: :nextjs, root_dir: "path", name: "my-project"}]
      }

      assert {:ok, %Repository{} = repository} = Repositories.create_repository(user, valid_attrs)
      assert repository.external_id == "github:789012"
      assert repository.name == "name"
      assert repository.owner == "user"
    end

    test "create_repository/1 with invalid data returns error changeset" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Repositories.create_repository(user, @invalid_attrs)
    end

    test "create_repositories/2 with valid data creates a list of repositories for some user" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)

      valid_attrs = [
        %{external_id: "github:123456", name: "name", owner: user.username},
        %{external_id: "github:789012", name: "name2", owner: user.username}
      ]

      assert {:ok, [%Repository{}, %Repository{}]} =
               Repositories.create_repositories(user, valid_attrs)
    end

    test "create_repositories/2 updates existing repository with new name and owner" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)

      initial_attrs = [
        %{external_id: "github:123456", name: "initial_name", owner: user.username}
      ]

      {:ok, [initial_repo]} = Repositories.create_repositories(user, initial_attrs)

      update_attrs = [
        %{external_id: "github:123456", name: "updated_name", owner: user.username}
      ]

      {:ok, [updated_repo]} = Repositories.create_repositories(user, update_attrs)

      assert updated_repo.id == initial_repo.id
      assert updated_repo.external_id == "github:123456"
      assert updated_repo.name == "updated_name"
      assert updated_repo.owner == user.username
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

      assert repository == Repositories.get_repository!(repository.id)
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

      assert Repositories.get_repository_by_external_id!("github:555777") == repository
    end

    test "get_repository_by_external_id!/1 raises error when repository doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Repositories.get_repository_by_external_id!("github:nonexistent")
      end
    end

    test "get_repository_by_external_id/1 returns the repository with given external_id" do
      user = Swarm.AccountsFixtures.user_fixture()
      repository = repository_fixture(user, %{external_id: "github:444333"})

      assert Repositories.get_repository_by_external_id("github:444333") == repository
    end

    test "get_repository_by_external_id/1 returns nil when repository doesn't exist" do
      assert Repositories.get_repository_by_external_id("github:nonexistent") == nil
    end

    test "validates external_id format" do
      user = Swarm.AccountsFixtures.user_fixture(%{username: "testuser"})
      _organization = personal_organization_fixture(user)

      # Should fail with changeset error for invalid format
      assert {:error, %Ecto.Changeset{}} =
               Repositories.create_repository(user, %{
                 external_id: "invalid-format",
                 name: "test",
                 owner: "testuser"
               })
    end

    test "enforces unique constraint on external_id" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)

      # Create first repository
      attrs = %{external_id: "github:123456", name: "repo_name", owner: user.username}
      assert {:ok, %Repository{}} = Repositories.create_repository(user, attrs)

      # Try to create another repository with same external_id (should fail)
      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(user, %{
                 external_id: "github:123456",
                 name: "different_name",
                 owner: user.username
               })

      assert [
               external_id:
                 {_, [constraint: :unique, constraint_name: "repositories_external_id_index"]}
             ] = changeset.errors

      # Different external_id should work even with same name and owner
      assert {:ok, %Repository{}} =
               Repositories.create_repository(user, %{
                 external_id: "github:654321",
                 name: "repo_name",
                 owner: user.username
               })
    end

    test "validates name length" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)

      # Name too short (less than 3 characters)
      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(user, %{
                 external_id: "github:123456",
                 name: "ab",
                 owner: user.username
               })

      assert {:name,
              {"should be at least %{count} character(s)",
               [count: 3, validation: :length, kind: :min, type: :string]}} in changeset.errors

      # Name too long (more than 100 characters)
      long_name = String.duplicate("a", 101)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(user, %{
                 external_id: "github:123456",
                 name: long_name,
                 owner: user.username
               })

      assert {:name,
              {"should be at most %{count} character(s)",
               [count: 100, validation: :length, kind: :max, type: :string]}} in changeset.errors
    end

    test "validates name format" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)

      # Invalid characters in name
      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(user, %{
                 external_id: "github:123456",
                 name: "invalid@name",
                 owner: user.username
               })

      assert changeset.errors[:name]
    end

    test "validates reserved names" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(user, %{
                 external_id: "github:123456",
                 name: "admin",
                 owner: user.username
               })

      assert {:name, {"is reserved", [validation: :exclusion, enum: ["admin", "system", "root"]]}} in changeset.errors
    end

    test "build_repository_url/1 returns the correct GitHub URL" do
      repository = %Repository{
        external_id: "github:123456",
        name: "my-repo",
        owner: "myuser"
      }

      assert Repository.build_repository_url(repository) ==
               "https://github.com/myuser/my-repo.git"
    end

    test "validates external_id format for repositories" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)

      # Valid format
      valid_attrs = %{external_id: "github:123456", name: "test-repo", owner: "user"}
      assert {:ok, %Repository{}} = Repositories.create_repository(user, valid_attrs)

      # Invalid format (missing colon)
      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(user, %{
                 external_id: "github123456",
                 name: "test-repo",
                 owner: "user"
               })

      assert changeset.errors[:external_id]

      # Invalid format (non-numeric ID)
      assert {:error, %Ecto.Changeset{} = changeset} =
               Repositories.create_repository(user, %{
                 external_id: "github:abc",
                 name: "test-repo",
                 owner: "testuser"
               })

      assert changeset.errors[:external_id]
    end

    test "create_repositories/2 updates existing repository linear_team_external_ids" do
      user = Swarm.AccountsFixtures.user_fixture()
      _organization = personal_organization_fixture(user)

      initial_attrs = [
        %{
          external_id: "github:123456",
          name: "initial_name",
          owner: user.username,
          linear_team_external_ids: ["team1", "team2"]
        }
      ]

      {:ok, [initial_repo]} = Repositories.create_repositories(user, initial_attrs)

      update_attrs = [
        %{
          external_id: "github:123456",
          name: "updated_name",
          owner: user.username,
          linear_team_external_ids: ["team3", "team4", "team5"]
        }
      ]

      {:ok, [updated_repo]} = Repositories.create_repositories(user, update_attrs)

      assert updated_repo.id == initial_repo.id
      assert updated_repo.external_id == "github:123456"
      assert updated_repo.name == "updated_name"
      assert updated_repo.owner == user.username
      assert updated_repo.linear_team_external_ids == ["team3", "team4", "team5"]
    end
  end
end
