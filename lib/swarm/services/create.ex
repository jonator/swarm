defmodule Swarm.Services.Create do
  @moduledoc false
  alias Swarm.Repo
  alias Swarm.Accounts.User
  alias Swarm.Projects.Project
  alias Swarm.Repositories.Repository

  def user_repo_and_project(%User{} = user, repository_attrs) do
    %Repository{}
    |> Repository.changeset(repository_attrs)
    |> Ecto.Changeset.put_assoc(:users, [user])
    |> Ecto.Changeset.cast_assoc(:projects, with: &Project.changeset/2)
    |> Repo.insert()
  end
end
