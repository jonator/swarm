defmodule Swarm.ProjectsTest do
  use Swarm.DataCase

  alias Swarm.Projects

  describe "projects" do
    alias Swarm.Projects.Project

    import Swarm.ProjectsFixtures

    @invalid_attrs %{type: nil, root_dir: "has space"}

    test "list_projects/0 returns all projects" do
      project = project_fixture()

      assert Enum.map(
               Projects.list_projects(),
               &Map.take(&1, [:id, :type, :root_dir, :repository_id])
             ) ==
               [Map.take(project, [:id, :type, :root_dir, :repository_id])]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()

      assert Map.take(Projects.get_project!(project.id), [
               :id,
               :type,
               :root_dir,
               :repository_id
             ]) ==
               Map.take(project, [:id, :type, :root_dir, :repository_id])
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{
        type: :nextjs,
        root_dir: "./root_dir",
        repository: %{
          name: "somenew/name"
        }
      }

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs)
      assert project.type == :nextjs
      assert project.root_dir == "./root_dir"
      assert project.repository.name == "somenew/name"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      update_attrs = %{type: :nextjs, root_dir: "./updated_root_dir"}

      assert {:ok, %Project{} = project} =
               Projects.update_project(project, update_attrs)

      assert project.type == :nextjs
      assert project.root_dir == "./updated_root_dir"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Projects.update_project(project, @invalid_attrs)

      assert project ==
               Projects.get_project!(project.id) |> Repo.preload(:repository)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end
end
