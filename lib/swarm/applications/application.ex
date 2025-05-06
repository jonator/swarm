defmodule Swarm.Applications.Application do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "applications" do
    field :type, Ecto.Enum, values: [:nextjs]
    field :root_dir, :string, default: "."
    belongs_to :repository, Swarm.Repositories.Repository

    timestamps()
  end

  @doc false
  def changeset(application, attrs) do
    application
    |> cast(attrs, [:root_dir, :type])
    |> validate_required([:type])
    |> validate_format(:root_dir, ~r/^[a-zA-Z0-9_\-\/\.]+$/, message: "must be a valid path")
  end
end
