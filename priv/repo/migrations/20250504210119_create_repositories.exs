defmodule Swarm.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add :external_id, :string, null: false, unique: true
      add :name, :string, null: false
      add :owner, :string, null: false
      add :linear_team_external_ids, {:array, :string}
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:repositories, [:external_id])
    create index(:repositories, [:organization_id])
  end
end
