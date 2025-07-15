defmodule Swarm.Repo.Migrations.CreateIdentities do
  use Ecto.Migration

  def change do
    create table(:identities) do
      add :provider, :string, null: false
      add :external_id, :string, null: false
      add :email, :string
      add :username, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:identities, [:provider, :external_id])
    create index(:identities, [:user_id])
  end
end
