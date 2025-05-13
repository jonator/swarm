defmodule Swarm.Accounts.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Repositories.Repository
  alias Swarm.Organizations.Organization
  alias Swarm.Accounts.UserOrganization
  alias Swarm.Accounts.Token

  schema "users" do
    field :email, :string
    field :username, :string
    field :role, Ecto.Enum, values: [:admin, :user], default: :user
    many_to_many :repositories, Repository, join_through: "users_repositories"
    many_to_many :organizations, Organization, join_through: UserOrganization
    has_many :tokens, Token

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :role])
    |> validate_required([:username])
    |> unique_constraint([:email, :username])
    |> validate_format(:email, ~r/^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/)
    |> validate_format(:username, ~r/^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$/i)
    |> validate_exclusion(:username, reserved_usernames())
  end

  defp reserved_usernames do
    [
      "help",
      "about",
      "pricing",
      "contact",
      "login",
      "logout",
      "signin",
      "signout",
      "register",
      "search",
      "explore",
      "features",
      "settings",
      "orgs",
      "organizations",
      "dashboard",
      "feeds",
      "admin"
    ]
  end
end
