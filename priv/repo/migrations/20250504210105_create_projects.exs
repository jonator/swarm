defmodule Swarm.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :root_dir, :string, null: false
      add :type, :string, null: false
      add :repository_id, references(:repositories, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:projects, [:repository_id])
  end
end
