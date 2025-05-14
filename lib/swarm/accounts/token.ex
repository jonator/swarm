defmodule Swarm.Accounts.Token do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "tokens" do
    field :token, :string
    field :context, Ecto.Enum, values: [:github]
    field :type, Ecto.Enum, values: [:access, :refresh]
    field :expires, :utc_datetime

    belongs_to :user, Swarm.Accounts.User

    timestamps()
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:token, :context, :type, :expires])
    |> validate_required([:token, :context, :type, :expires])
  end

  def is_expired(%__MODULE__{} = token) do
    DateTime.after?(token.expires, DateTime.utc_now())
  end
end
