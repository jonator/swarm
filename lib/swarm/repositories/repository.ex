defmodule Swarm.Repositories.Repository do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Swarm.Organizations.Organization
  alias Swarm.Projects.Project

  schema "repositories" do
    # format: provider:id (e.g., github:1234556)
    field :external_id, :string
    field :name, :string
    field :owner, :string
    field :linear_team_external_ids, {:array, :string}, default: []
    belongs_to :organization, Organization
    has_many :projects, Project

    timestamps()
  end

  @doc false
  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:external_id, :name, :owner, :linear_team_external_ids])
    |> validate_required([:external_id, :name, :owner])
    |> update_change(:name, &String.trim/1)
    |> validate_format(:external_id, ~r/^[a-zA-Z0-9_-]+:[0-9]+$/,
      message: "must be in format 'provider:id' (e.g., 'github:1234556')"
    )
    |> unique_constraint(:external_id)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_format(:name, ~r/^[a-zA-Z0-9 _\-\/\.]+$/,
      message:
        "can only contain letters, numbers, spaces, underscores, hyphens, slashes, and periods"
    )
    |> validate_exclusion(:name, ["admin", "system", "root"], message: "is reserved")
  end

  @doc """
  Builds the git clone URL for a repository.

  Currently supports GitHub repositories. Returns a git clone URL
  based on the repository's external_id, owner, and name.

  ## Examples

      iex> repo = %Repository{external_id: "github:123", owner: "myorg", name: "myrepo"}
      iex> Repository.build_repository_url(repo)
      "https://github.com/myorg/myrepo.git"

  """
  def build_repository_url(%__MODULE__{
        external_id: "github:" <> _github_id,
        name: name,
        owner: owner
      }) do
    "https://github.com/#{owner}/#{name}.git"
  end
end
