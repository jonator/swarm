defmodule Swarm.Services do
  @moduledoc """
  This module provides functions for enacting actions on internal and external APIs.
  """

  alias Swarm.Accounts.User
  alias Swarm.Services.GitHub
  alias Swarm.Framework

  defdelegate github(user), to: GitHub, as: :new

  @doc """
  Detects the frameworks used in a GitHub repository by analyzing its file structure.

  ## Parameters
    - user: The authenticated user record
    - owner: GitHub repository owner
    - repo: GitHub repository name
    - branch: Repository branch to analyze

  ## Returns
    - `{:ok, list}` - List of detected frameworks
    - `{:error, reason}` - If the detection failed
  """
  def detect_github_repository_frameworks(%User{} = user, owner, repo, branch) do
    with {:ok, trees} <- GitHub.repository_trees(user, owner, repo, branch) do
      {:ok, Framework.detect(trees)}
    end
  end
end
