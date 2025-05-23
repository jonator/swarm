defmodule Swarm.Repositories.Repository do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Accounts.User
  alias Swarm.Organizations.Organization
  alias Swarm.Projects.Project

  schema "repositories" do
    field :external_id, :string
    field :name, :string
    field :owner, :string
    many_to_many :users, User, join_through: "users_repositories"
    many_to_many :organizations, Organization, join_through: "organizations_repositories"
    has_many :projects, Project

    timestamps()
  end

  @doc false
  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:external_id, :name, :owner])
    |> validate_required([:external_id, :name, :owner])
    |> update_change(:name, &String.trim/1)
    |> validate_format(:external_id, ~r/^[a-zA-Z0-9_-]+:[0-9]+$/,
      message: "must be in format 'provider:id' (e.g., 'github:1234556')"
    )
    |> unique_constraint(:external_id)
    |> unique_constraint([:name, :owner])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_format(:name, ~r/^[a-zA-Z0-9 _\-\/]+$/,
      message: "can only contain letters, numbers, spaces, underscores, hyphens, and slashes"
    )
    |> validate_exclusion(:name, ["admin", "system", "root"], message: "is reserved")
  end
end
