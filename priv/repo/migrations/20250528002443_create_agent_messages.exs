defmodule Swarm.Repo.Migrations.CreateAgentMessages do
  use Ecto.Migration

  def change do
    create table(:agent_messages) do
      add :index, :integer, null: false
      add :content, :map, null: false, default: %{}
      add :type, :string, null: false
      add :agent_id, references(:agents, type: :uuid, on_delete: :delete_all)

      timestamps()
    end

    create index(:agent_messages, [:agent_id])
  end
end
