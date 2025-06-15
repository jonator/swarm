defmodule Swarm.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Projects` context.
  """

  import Swarm.RepositoriesFixtures

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    repository = repository_fixture() |> Map.from_struct()

    {:ok, project} =
      attrs
      |> Enum.into(%{
        root_dir: "./root_dir",
        type: :nextjs,
        name: "@nextjs-package/tests",
        repository_id: repository.id
      })
      |> Swarm.Projects.create_project()

    project
  end
end
