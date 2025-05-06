defmodule Swarm.Organizations.Organization do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Accounts.User
  alias Swarm.Accounts.UserOrganization
  alias Swarm.Repositories.Repository

  schema "organizations" do
    field :name, :string
    many_to_many :users, User, join_through: UserOrganization
    many_to_many :repositories, Repository, join_through: "organizations_repositories"

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> update_change(:name, &String.trim/1)
    |> unique_constraint(:name)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_format(:name, ~r/^[a-zA-Z0-9_-]+$/,
      message: "can only contain letters, numbers, underscores, and hyphens"
    )
    |> validate_exclusion(:name, ["admin", "system", "root"], message: "is reserved")
  end
end
