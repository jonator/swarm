defmodule Swarm.Services do
  @moduledoc """
  This module provides functions for enacting actions on internal and external APIs.
  """

  alias Swarm.Accounts.User
  alias Swarm.Services.GitHub
  alias Swarm.Services.Linear
  alias Swarm.Framework
  alias Swarm.Repositories
  alias Swarm.Organizations

  defdelegate github(user), to: GitHub, as: :new
  defdelegate linear(user), to: Linear, as: :new

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
      frameworks =
        Framework.detect(trees)
        |> Enum.reduce([], fn framework, acc ->
          case framework do
            %{type: "nextjs", path: dir} ->
              with {:ok, package_json_content} <-
                     GitHub.repository_file_content(user, owner, repo, dir <> "/package.json"),
                   {:ok, package_json} <- Jason.decode(package_json_content),
                   {:ok, name} <- Map.fetch(package_json, "name") do
                [%{type: "nextjs", path: dir, name: name} | acc]
              else
                _ -> acc
              end

            _ ->
              acc
          end
        end)

      {:ok, frameworks}
    end
  end

  @doc """
  Creates a repository from a GitHub repository ID and optional project attributes.

  This function fetches the repository details from GitHub's API, validates that the user
  owns the repository, creates or gets an organization for the user, and creates
  a repository record with optional project data.

  ## Parameters
    - user: The authenticated user record
    - github_repo_id: GitHub repository ID (numeric string or integer)
    - project_data: Map containing projects array and optional name:
      - projects: [%{name: ..., type: ...}, ...] (optional)
      - name: repository name override (optional)

  ## Returns
    - `{:ok, repository}` - Successfully created repository
    - `{:error, reason}` - If the creation failed (GitHub API error, validation error, or changeset error)

  ## Examples

      # Create repository with projects
      iex> Services.create_repository_from_github(user, "123456", %{
      ...>   projects: [%{name: "frontend", type: "nextjs"}, %{name: "backend", type: "elixir"}]
      ...> })
      {:ok, %Repository{external_id: "github:123456", name: "my-repo"}}

      # Create repository without projects (minimal)
      iex> Services.create_repository_from_github(user, "789012")
      {:ok, %Repository{external_id: "github:789012", name: "repo-789012"}}

      # Error when repository not accessible
      iex> Services.create_repository_from_github(user, "999999")
      {:error, "Repository with ID 999999 not found in user's accessible repositories"}

      # Error when user doesn't own the repository
      iex> Services.create_repository_from_github(user, "111111")
      {:error, "Repository owner 'otheruser' does not match user 'myuser'"}
  """
  def create_repository_from_github(
        %User{username: username} = user,
        github_repo_id,
        projects \\ [%{}]
      ) do
    with {:ok, github_repo, github_installation_id} <-
           fetch_github_repository(user, github_repo_id),
         {:ok, organization} <-
           Organizations.get_or_create_organization(
             user,
             github_repo["owner"]["login"],
             github_installation_id
           ) do
      # Filter to only valid projects
      valid_projects = Enum.filter(projects, &has_required_project_fields?/1)

      repo_attrs = %{
        external_id: "github:#{github_repo_id}",
        name: github_repo["name"],
        owner: username
      }

      # Add projects to repo_attrs only if we have valid projects
      repo_attrs_with_projects =
        if length(valid_projects) > 0 do
          Map.put(repo_attrs, :projects, valid_projects)
        else
          repo_attrs
        end

      Repositories.create_repository(organization, repo_attrs_with_projects)
    end
  end

  @doc """
  Fetches a GitHub repository by ID from all the user's accessible repositories across all installations.

  This function queries GitHub's installations API to get all installations, then searches
  repositories across all installations to find a repository by its numeric ID.

  ## Parameters
    - user: The authenticated user record with valid GitHub tokens
    - github_repo_id: GitHub repository ID (numeric string or integer)

  ## Returns
    - `{:ok, repository_map, installation_id}` - GitHub repository data containing id, name, owner, etc and the associated installation id.
    - `{:error, reason}` - If the repository could not be found or accessed

  ## Examples

      iex> Services.fetch_github_repository(user, "123456")
      {:ok, %{
        "id" => 123456,
        "name" => "my-repo",
        "owner" => %{"login" => "myuser"},
        "full_name" => "myuser/my-repo",
        ...
      }}

      iex> Services.fetch_github_repository(user, "999999")
      {:error, "Repository with ID 999999 not found in user's accessible repositories"}
  """
  def fetch_github_repository(%User{} = user, github_repo_id) do
    repo_id =
      if is_binary(github_repo_id), do: String.to_integer(github_repo_id), else: github_repo_id

    with {:ok, gh_client} <- GitHub.new(user) do
      case GitHub.installations(gh_client) do
        {:ok, %{"installations" => installations}} ->
          search_repositories_across_installations(gh_client, installations, repo_id, github_repo_id)

        {:error, reason} ->
          {:error, "Failed to fetch GitHub installations: #{reason}"}

          error ->
            {:error, "Failed to fetch GitHub installations: #{inspect(error)}"}
        end
      end
  end

  defp search_repositories_across_installations(gh_client, installations, repo_id, github_repo_id) do
    installations
    |> Enum.reduce_while({:not_found, []}, fn installation, {_status, errors} ->
      case GitHub.installation_repositories(gh_client, installation["id"]) do
        {:ok, %{"repositories" => repositories}} ->
          case Enum.find(repositories, &(&1["id"] == repo_id)) do
            nil ->
              {:cont, {:not_found, errors}}

            repository ->
              {:halt, {:found, repository, installation["id"]}}
          end

        {:error, reason} ->
          {:cont, {:not_found, [reason | errors]}}

        _error ->
          {:cont, {:not_found, ["Unknown error fetching repositories" | errors]}}
      end
    end)
    |> case do
      {:found, repository, installation_id} ->
        {:ok, repository, installation_id}

      {:not_found, []} ->
        {:error,
         "Repository with ID #{github_repo_id} not found in user's accessible repositories"}

      {:not_found, errors} ->
        {:error,
         "Repository with ID #{github_repo_id} not found. Errors encountered: #{Enum.join(errors, ", ")}"}
    end
  end

  @doc """
  Fetches all GitHub repositories accessible to the user across all GitHub installations.
  This includes both personal repositories and repositories from organizations the user has granted Swarm access to (orgs they have app manager access to, see: https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/roles-in-an-organization#github-app-managers).
  NOTE: This is important since we assume repos with new "owner" become new Swarm orgs, and if it's the first user they become the owner of the Swarm org.
  """
  def fetch_all_github_repositories(%User{} = user) do
    {:ok, gh_client} = GitHub.new(user)

    case GitHub.installations(gh_client) do
      {:ok, %{"installations" => installations}} ->
        repositories_across_all_installations(gh_client, installations)

      {:error, reason} ->
        {:error, "Failed to fetch GitHub installations: #{reason}"}

      error ->
        error
    end
  end

  defp repositories_across_all_installations(gh_client, installations) do
    installations
    |> Enum.reduce_while({:ok, []}, fn installation, {:ok, acc_repos} ->
      case GitHub.installation_repositories(gh_client, installation["id"]) do
        {:ok, %{"repositories" => installation_repos}} ->
          {:cont, {:ok, acc_repos ++ installation_repos}}

        {:error, reason} ->
          {:cont,
           {:error,
            "Failed to fetch repositories for installation #{installation["id"]}: #{reason}"}}

        _error ->
          {:cont,
           {:error, "Unknown error fetching repositories for installation #{installation["id"]}"}}
      end
    end)
    |> case do
      {:ok, repositories} -> {:ok, repositories}
      {:error, reason} -> {:error, reason}
    end
  end

  defp has_required_project_fields?(project_attrs) do
    name = project_attrs["name"] || project_attrs[:name]
    type = project_attrs["type"] || project_attrs[:type]

    name != nil and type != nil and map_size(project_attrs) > 0
  end
end
