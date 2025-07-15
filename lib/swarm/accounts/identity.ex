defmodule Swarm.Accounts.Identity do
  @moduledoc """
  An identity is a user's account on a provider.

  It is used to identify and link a user across providers.

  It is also used to identify a user across installations and emails.

  GitHub is not included as it's the primary login method and can be found on User schema.

  Examples include linear, slack.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "identities" do
    field :provider, Ecto.Enum, values: [:slack, :linear]
    # No provider prefix, is above
    field :external_id, :string
    field :email, :string
    field :username, :string
    belongs_to :user, Swarm.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:provider, :external_id, :email, :username, :user_id])
    |> validate_required([:provider, :external_id, :email, :username, :user_id])
    |> unique_constraint([:provider, :external_id])
    |> validate_format(:email, ~r/^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/)
    |> validate_format(:username, ~r/^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$/i)
  end
end
