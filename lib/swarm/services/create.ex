defmodule Swarm.Services.Create do
  alias Swarm.Repo
  alias Swarm.Accounts.User
  alias Swarm.Applications.Application
  alias Swarm.Repositories.Repository

  def user_repo_and_application(user = %User{}, repository_attrs) do
    %Repository{}
    |> Repository.changeset(repository_attrs)
    |> Ecto.Changeset.put_assoc(:users, [user])
    |> Ecto.Changeset.cast_assoc(:applications, with: &Application.changeset/2)
    |> Repo.insert()
  end
end
