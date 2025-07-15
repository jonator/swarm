defmodule Swarm.Accounts.User do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset
  alias Swarm.Organizations.Organization
  alias Swarm.Accounts.UserOrganization
  alias Swarm.Accounts.Token
  alias Swarm.Accounts.Identity

  schema "users" do
    # These are GitHub centric fields.
    # We leave these here for convenience since this app is GitHub centric.
    field :email, :string
    field :username, :string
    field :avatar_url, :string

    field :role, Ecto.Enum, values: [:admin, :user], default: :user
    many_to_many :organizations, Organization, join_through: UserOrganization
    has_many :tokens, Token
    has_many :identities, Identity

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :role, :avatar_url])
    |> validate_required([:username])
    |> unique_constraint([:email, :username])
    |> validate_format(:email, ~r/^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/)
    |> validate_format(:username, ~r/^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$/i)
    |> validate_length(:avatar_url, max: 255)
    |> validate_format(
      :avatar_url,
      ~r/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/
    )
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
