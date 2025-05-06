defmodule Swarm.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add :name, :string, null: false, unique: true

      timestamps()
    end

    create table("users_repositories", primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :repository_id, references(:repositories, on_delete: :delete_all), null: false

      # timestamps()
    end

    create unique_index(:users_repositories, [:user_id, :repository_id])
  end
end
