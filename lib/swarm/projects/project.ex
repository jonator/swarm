defmodule Swarm.Projects.Project do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :type, Ecto.Enum, values: [:nextjs]
    field :root_dir, :string, default: "."
    field :name, :string
    belongs_to :repository, Swarm.Repositories.Repository

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:root_dir, :type, :name])
    |> validate_required([:type, :name])
    |> validate_format(:root_dir, ~r/^[a-zA-Z0-9_\-\/\.]+$/, message: "must be a valid path")
    |> validate_format(:name, ~r/^(?:(?:@(?:[a-z0-9-*~][a-z0-9-*._~]*)?\/[a-z0-9-._~])|[a-z0-9-~])[a-z0-9-._~]*$/, message: "must be a valid package name")
    |> cast_assoc(:repository)
  end
end
