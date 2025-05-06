defmodule Swarm.Repo.Migrations.CreateApplications do
  use Ecto.Migration

  def change do
    create table(:applications) do
      add :root_dir, :string, null: false
      add :type, :string, null: false
      add :repository_id, references(:repositories, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:applications, [:repository_id])
  end
end
