defmodule Swarm.Repo.Migrations.CreateAgents do
  use Ecto.Migration

  def change do
    create table(:agents, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :name, :string, null: false
      add :context, :text, null: false
      add :status, :string, null: false
      add :source, :string, null: false
      add :type, :string, null: false
      add :github_pull_request_id, :string
      add :github_issue_id, :string
      add :linear_issue_id, :string
      add :linear_document_id, :string
      add :slack_thread_id, :string
      add :started_at, :naive_datetime
      add :completed_at, :naive_datetime
      add :oban_job_id, references(:oban_jobs, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :repository_id, references(:repositories, on_delete: :nothing)
      add :project_id, references(:projects, on_delete: :nothing)

      timestamps()
    end

    create index(:agents, [:oban_job_id])
    create index(:agents, [:user_id])
    create index(:agents, [:repository_id])
    create index(:agents, [:project_id])
  end
end
