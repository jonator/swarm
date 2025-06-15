defmodule Swarm.Organizations.Organization do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Accounts.User
  alias Swarm.Accounts.UserOrganization
  alias Swarm.Repositories.Repository

  schema "organizations" do
    field :name, :string
    field :github_installation_id, :integer
    many_to_many :users, User, join_through: UserOrganization
    has_many :repositories, Repository

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :github_installation_id])
    |> validate_required([:name])
    |> update_change(:name, &String.trim/1)
    |> unique_constraint(:name)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_format(:name, ~r/^[a-zA-Z0-9_-]+$/,
      message: "can only contain letters, numbers, underscores, and hyphens"
    )
    |> validate_exclusion(:name, ["admin", "system", "root"], message: "is reserved")
    |> validate_number(:github_installation_id, greater_than: 0)
  end
end
