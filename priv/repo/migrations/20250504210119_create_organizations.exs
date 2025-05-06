defmodule Swarm.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false, unique: true

      timestamps()
    end

    create table("organizations_repositories", primary_key: false) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :repository_id, references(:repositories, on_delete: :delete_all), null: false

      # timestamps()
    end

    create table(:users_organizations, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :role, :string, null: false

      # we're using a join schema, so we can extract role and timestamps into elixir structs
      timestamps()
    end

    create unique_index(:organizations_repositories, [:organization_id, :repository_id])
    create unique_index(:users_organizations, [:user_id, :organization_id])
  end
end
