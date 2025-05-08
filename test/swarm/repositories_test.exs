defmodule Swarm.RepositoriesTest do
  use Swarm.DataCase

  alias Swarm.Repositories

  describe "repositories" do
    alias Swarm.Repositories.Repository

    import Swarm.RepositoriesFixtures

    @invalid_attrs %{name: nil, owner: nil}

    test "list_repositories/0 returns all repositories" do
      repository = repository_fixture()
      assert Repositories.list_repositories() == [repository]
    end

    test "get_repository!/1 returns the repository with given id" do
      repository = repository_fixture()
      assert Repositories.get_repository!(repository.id) == repository
    end

    test "create_repository/1 with valid data creates a repository" do
      valid_attrs = %{name: "name", owner: "some_owner"}

      assert {:ok, %Repository{} = repository} = Repositories.create_repository(valid_attrs)
      assert repository.name == "name"
      assert repository.owner == "some_owner"
    end

    test "create_repository/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Repositories.create_repository(@invalid_attrs)
    end

    test "update_repository/2 with valid data updates the repository" do
      repository = repository_fixture()
      update_attrs = %{name: "updated_name", owner: "updated_owner"}

      assert {:ok, %Repository{} = repository} =
               Repositories.update_repository(repository, update_attrs)

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
  end
end
