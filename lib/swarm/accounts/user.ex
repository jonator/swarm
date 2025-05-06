defmodule Swarm.Accounts.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Repositories.Repository
  alias Swarm.Organizations.Organization
  alias Swarm.Accounts.UserOrganization

  schema "users" do
    field :email, :string
    field :role, Ecto.Enum, values: [:admin, :user], default: :user
    many_to_many :repositories, Repository, join_through: "users_repositories"
    many_to_many :organizations, Organization, join_through: UserOrganization

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :role])
    |> validate_required([:email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/)
    |> cast_assoc(:repositories)
    |> cast_assoc(:organizations)
  end
end
