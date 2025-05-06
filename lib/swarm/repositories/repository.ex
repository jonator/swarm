defmodule Swarm.Repositories.Repository do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Accounts.User
  alias Swarm.Organizations.Organization
  alias Swarm.Applications.Application

  schema "repositories" do
    field :name, :string
    many_to_many :users, User, join_through: "users_repositories"
    many_to_many :organizations, Organization, join_through: "organizations_repositories"
    has_many :applications, Application

    timestamps()
  end

  @doc false
  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> update_change(:name, &String.trim/1)
    |> unique_constraint(:name)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_format(:name, ~r/^[a-zA-Z0-9 _\-\/]+$/,
      message: "can only contain letters, numbers, spaces, underscores, hyphens, and slashes"
    )
    |> validate_exclusion(:name, ["admin", "system", "root"], message: "is reserved")
  end
end
