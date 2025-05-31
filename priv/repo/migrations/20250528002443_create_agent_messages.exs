defmodule Swarm.Repo.Migrations.CreateAgentMessages do
  use Ecto.Migration

  def change do
    create table(:agent_messages) do
      add :content, :text, null: false
      add :type, :string, null: false
      add :agent_id, references(:agents, on_delete: :delete_all)

      timestamps()
    end

    create index(:agent_messages, [:agent_id])
  end
end
