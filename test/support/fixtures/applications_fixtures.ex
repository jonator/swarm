defmodule Swarm.ApplicationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Applications` context.
  """

  @doc """
  Generate a application.
  """
  def application_fixture(attrs \\ %{}) do
    {:ok, application} =
      attrs
      |> Enum.into(%{
        root_dir: "./root_dir",
        type: :nextjs,
        repository: %{
          name: "some/name"
        }
      })
      |> Swarm.Applications.create_application()

    application
  end
end
