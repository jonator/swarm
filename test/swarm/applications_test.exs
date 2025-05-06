defmodule Swarm.ApplicationsTest do
  use Swarm.DataCase

  alias Swarm.Applications

  describe "applications" do
    alias Swarm.Applications.Application

    import Swarm.ApplicationsFixtures

    @invalid_attrs %{type: nil, root_dir: "has space"}

    test "list_applications/0 returns all applications" do
      application = application_fixture()

      assert Enum.map(
               Applications.list_applications(),
               &Map.take(&1, [:id, :type, :root_dir, :repository_id])
             ) ==
               [Map.take(application, [:id, :type, :root_dir, :repository_id])]
    end

    test "get_application!/1 returns the application with given id" do
      application = application_fixture()

      assert Map.take(Applications.get_application!(application.id), [
               :id,
               :type,
               :root_dir,
               :repository_id
             ]) ==
               Map.take(application, [:id, :type, :root_dir, :repository_id])
    end

    test "create_application/1 with valid data creates a application" do
      valid_attrs = %{
        type: :nextjs,
        root_dir: "./root_dir",
        repository: %{
          name: "somenew/name"
        }
      }

      assert {:ok, %Application{} = application} = Applications.create_application(valid_attrs)
      assert application.type == :nextjs
      assert application.root_dir == "./root_dir"
      assert application.repository.name == "somenew/name"
    end

    test "create_application/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Applications.create_application(@invalid_attrs)
    end

    test "update_application/2 with valid data updates the application" do
      application = application_fixture()
      update_attrs = %{type: :nextjs, root_dir: "./updated_root_dir"}

      assert {:ok, %Application{} = application} =
               Applications.update_application(application, update_attrs)

      assert application.type == :nextjs
      assert application.root_dir == "./updated_root_dir"
    end

    test "update_application/2 with invalid data returns error changeset" do
      application = application_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Applications.update_application(application, @invalid_attrs)

      assert application ==
               Applications.get_application!(application.id) |> Repo.preload(:repository)
    end

    test "delete_application/1 deletes the application" do
      application = application_fixture()
      assert {:ok, %Application{}} = Applications.delete_application(application)
      assert_raise Ecto.NoResultsError, fn -> Applications.get_application!(application.id) end
    end

    test "change_application/1 returns a application changeset" do
      application = application_fixture()
      assert %Ecto.Changeset{} = Applications.change_application(application)
    end
  end
end
