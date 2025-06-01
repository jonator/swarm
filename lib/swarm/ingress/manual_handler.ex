defmodule Swarm.Ingress.ManualHandler do
  @moduledoc """
  Handles manual agent spawn requests from the frontend or API.

  This handler processes direct requests to spawn agents with:
  - Specific repository and project context
  - Custom agent types and configurations
  - Direct user input and requirements
  """

  require Logger

  alias Swarm.Ingress.Event
  alias Swarm.Ingress.Permissions
  alias Swarm.Repositories

  @doc """
  Handles a manual agent spawn request.

  ## Parameters
    - event: Standardized event struct from manual trigger

  ## Returns
    - `{:ok, agent_attrs}` - Successfully built agent attributes for spawning
    - `{:error, reason}` - Event processing failed
  """
  def handle(%Event{source: :manual} = event) do
    Logger.info("Processing manual agent spawn request")

    with {:ok, user} <- Permissions.validate_user_access(event),
         {:ok, repository} <- find_repository(user, event),
         {:ok, agent_attrs} <- build_agent_attributes(event, user, repository) do
      agent_attrs
    else
      {:error, reason} = error ->
        Logger.warning("Manual agent spawn failed: #{reason}")
        error
    end
  end

  def handle(%Event{source: other_source}) do
    {:error, "ManualHandler received non-manual event: #{other_source}"}
  end

  @doc """
  Finds the repository for a manual agent spawn request.
  """
  def find_repository(user, %Event{repository_external_id: repo_id}) when not is_nil(repo_id) do
    case Repositories.get_user_repository(user, repo_id) do
      nil -> {:error, "Repository not found or user does not have access: #{repo_id}"}
      repository -> {:ok, repository}
    end
  end

  def find_repository(user, %Event{context: context}) do
    # Try to find repository from context
    cond do
      context[:repository_id] ->
        case Repositories.get_user_repository(user, context[:repository_id]) do
          nil ->
            {:error,
             "Repository not found or user does not have access: #{context[:repository_id]}"}

          repository ->
            {:ok, repository}
        end

      context[:repository_external_id] ->
        case Repositories.get_user_repository(user, context[:repository_external_id]) do
          nil -> {:error, "Repository not found: #{context[:repository_external_id]}"}
          repository -> {:ok, repository}
        end

      true ->
        # Use default repository if none specified
        find_default_repository(user)
    end
  end

  defp find_default_repository(user) do
    case Repositories.list_repositories(user) do
      [] ->
        {:error, "No repositories found for user"}

      [repository] ->
        {:ok, repository}

      repositories ->
        # Use the first repository as default, could be enhanced with user preferences
        {:ok, List.first(repositories)}
    end
  end

  @doc """
  Builds agent attributes from the manual request data.
  """
  def build_agent_attributes(%Event{context: context}, user, repository) do
    base_attrs = %{
      user_id: user.id,
      repository_id: repository.id,
      repository: repository,
      source: :manual,
      status: :pending
    }

    # Extract manual request specific attributes
    manual_attrs = %{
      context: determine_agent_context(context)
    }

    # Merge project ID if specified
    project_attrs =
      case context[:project_id] do
        nil -> %{}
        project_id -> %{project_id: project_id}
      end

    attrs = Map.merge(base_attrs, manual_attrs)
    attrs = Map.merge(attrs, project_attrs)

    {:ok, attrs}
  end

  defp determine_agent_context(context) do
    # Build context from provided information
    description = context[:description] || context["description"] || ""
    requirements = context[:requirements] || context["requirements"] || ""
    files = context[:files] || context["files"] || []

    context_parts =
      []
      |> add_description_part(description)
      |> add_requirements_part(requirements)
      |> add_files_part(files)

    case context_parts do
      [] -> "Manual agent request - no specific context provided"
      parts -> Enum.reverse(parts) |> Enum.join("\n\n")
    end
  end

  defp add_description_part(context_parts, description) do
    if description != "" do
      ["Description:\n#{description}" | context_parts]
    else
      context_parts
    end
  end

  defp add_requirements_part(context_parts, requirements) do
    if requirements != "" do
      ["Requirements:\n#{requirements}" | context_parts]
    else
      context_parts
    end
  end

  defp add_files_part(context_parts, files) do
    if length(files) > 0 do
      files_text = files |> Enum.join(", ")
      ["Files to focus on: #{files_text}" | context_parts]
    else
      context_parts
    end
  end
end
