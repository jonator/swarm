defmodule Swarm.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        root_dir: "./root_dir",
        type: :nextjs,
        repository: %{
          owner: "someowner",
          name: "somename"
        }
      })
      |> Swarm.Projects.create_project()

    project
  end
end
