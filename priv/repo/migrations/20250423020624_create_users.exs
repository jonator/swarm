defmodule Swarm.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, unique: true
      add :username, :string, null: false, unique: true
      add :role, :string, null: false
      add :avatar_url, :string

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])

    create table(:tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :context, :string, null: false
      add :type, :string, null: false
      add :linear_workspace_external_id, :string
      add :expires, :utc_datetime, null: false

      timestamps()
    end

    create index(:tokens, [:user_id])
    create index(:tokens, [:linear_workspace_external_id])
  end
end
