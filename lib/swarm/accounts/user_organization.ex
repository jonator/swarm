defmodule Swarm.Accounts.UserOrganization do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Accounts.User
  alias Swarm.Organizations.Organization

  @primary_key false
  schema "users_organizations" do
    belongs_to :user, User
    belongs_to :organization, Organization
    field :role, Ecto.Enum, values: [:admin, :member]

    timestamps()
  end

  def changeset(user_organization, attrs) do
    user_organization
    |> cast(attrs, [:role])
    |> validate_required([:role])
  end

  def delete_changeset(user_organization) do
    user_organization
    |> cast(%{}, [:role])
    |> validate_inclusion(:role, [:admin], message: "must be admin to delete organization")
  end
end
