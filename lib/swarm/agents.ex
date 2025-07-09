defmodule Swarm.Agents do
  @moduledoc """
  The Agents context.
  
  This module provides functions for managing agents, including:
  - Creating, reading, updating, and deleting agents
  - Filtering agents by various criteria
  - Managing agent lifecycle (pending, running, completed, failed)
  - Handling agent messages and communication
  """

  import Ecto.Query, warn: false
  alias Swarm.Repo

  alias Swarm.Agents.Agent
  alias Swarm.Accounts.User
  alias Swarm.Agents.Message

  @type agent_status :: :pending | :running | :completed | :failed

  # Agent CRUD Operations

  @doc """
  Returns the list of all agents.

  ## Examples

      iex> list_agents()
      [%Agent{}, ...]

  """
  @spec list_agents() :: [Agent.t()]
  def list_agents do
    Repo.all(Agent)
  end

  @doc """
  Returns the list of agents accessible by the given user.
  
  Filters agents based on user's organization membership and applies
  optional filters for repository and organization names.

  ## Parameters
    - user: The user requesting the agents
    - params: Optional filters (repository_name, organization_name)

  ## Examples

      iex> list_agents(user, %{"repository_name" => "my-repo"})
      [%Agent{}, ...]

  """
  @spec list_agents(User.t(), map()) :: [Agent.t()]
  def list_agents(%User{} = user, params \\ %{}) do
    user_organization_ids = get_user_organization_ids(user)

    build_user_agents_query(user_organization_ids)
    |> apply_filters(params)
    |> Repo.all()
  end

  @doc """
  Gets a single agent by ID.

  Raises `Ecto.NoResultsError` if the Agent does not exist.

  ## Examples

      iex> get_agent!(123)
      %Agent{}

      iex> get_agent!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_agent!(binary()) :: Agent.t()
  def get_agent!(id), do: Repo.get!(Agent, id)

  @doc """
  Gets a single agent by ID.

  Returns `nil` if the Agent does not exist or ID is invalid.

  ## Examples

      iex> get_agent("valid-uuid")
      %Agent{}

      iex> get_agent("invalid-id")
      nil

  """
  @spec get_agent(binary()) :: Agent.t() | nil
  def get_agent(id) do
    with {:ok, valid_id} <- validate_uuid(id) do
      Repo.get(Agent, valid_id)
    else
      :error -> nil
    end
  end

  @doc """
  Gets a single agent by ID that is accessible by the given user.
  
  Returns `nil` if the Agent does not exist, ID is invalid, or user lacks access.

  ## Examples

      iex> get_agent(user, "valid-uuid")
      %Agent{}

      iex> get_agent(user, "invalid-id")
      nil

  """
  @spec get_agent(User.t(), binary()) :: Agent.t() | nil
  def get_agent(%User{} = user, id) do
    with {:ok, valid_id} <- validate_uuid(id) do
      user_organization_ids = get_user_organization_ids(user)
      
      build_user_agents_query(user_organization_ids)
      |> where([a], a.id == ^valid_id)
      |> Repo.one()
    else
      :error -> nil
    end
  end

  @doc """
  Creates a new agent.

  ## Examples

      iex> create_agent(%{field: value})
      {:ok, %Agent{}}

      iex> create_agent(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_agent(map()) :: {:ok, Agent.t()} | {:error, Ecto.Changeset.t()}
  def create_agent(attrs \\ %{}) do
    %Agent{}
    |> Agent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing agent.

  ## Examples

      iex> update_agent(agent, %{field: new_value})
      {:ok, %Agent{}}

      iex> update_agent(agent, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_agent(Agent.t(), map()) :: {:ok, Agent.t()} | {:error, Ecto.Changeset.t()}
  def update_agent(%Agent{} = agent, attrs) do
    agent
    |> Agent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an agent.

  ## Examples

      iex> delete_agent(agent)
      {:ok, %Agent{}}

      iex> delete_agent(agent)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_agent(Agent.t()) :: {:ok, Agent.t()} | {:error, Ecto.Changeset.t()}
  def delete_agent(%Agent{} = agent) do
    Repo.delete(agent)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking agent changes.

  ## Examples

      iex> change_agent(agent)
      %Ecto.Changeset{data: %Agent{}}

  """
  @spec change_agent(Agent.t(), map()) :: Ecto.Changeset.t()
  def change_agent(%Agent{} = agent, attrs \\ %{}) do
    Agent.changeset(agent, attrs)
  end

  # Agent Lifecycle Management

  @doc """
  Marks an agent as started by setting started_at to now and status to running.
  """
  @spec mark_agent_started(Agent.t(), binary()) :: {:ok, Agent.t()} | {:error, Ecto.Changeset.t()}
  def mark_agent_started(%Agent{} = agent, oban_job_id) do
    update_agent(agent, %{
      status: :running,
      started_at: NaiveDateTime.utc_now(),
      oban_job_id: oban_job_id
    })
  end

  @doc """
  Marks an agent as completed by setting completed_at to now and status to completed.
  """
  @spec mark_agent_completed(Agent.t()) :: {:ok, Agent.t()} | {:error, Ecto.Changeset.t()}
  def mark_agent_completed(%Agent{} = agent) do
    update_agent(agent, %{
      status: :completed,
      completed_at: NaiveDateTime.utc_now()
    })
  end

  @doc """
  Marks an agent as failed by setting status to failed.
  """
  @spec mark_agent_failed(Agent.t()) :: {:ok, Agent.t()} | {:error, Ecto.Changeset.t()}
  def mark_agent_failed(%Agent{} = agent) do
    update_agent(agent, %{status: :failed})
  end

  # Agent Status Queries

  @doc """
  Gets agents by status.
  """
  @spec list_agents_by_status(agent_status()) :: [Agent.t()]
  def list_agents_by_status(status) when status in [:pending, :running, :completed, :failed] do
    from(a in Agent, where: a.status == ^status)
    |> Repo.all()
  end

  # Agent Conflict Detection

  @doc """
  Finds an agent that has overlapping external IDs with the given agent attributes.

  This checks for agents with the same Linear issue ID, GitHub issue ID,
  or other identifying attributes that would indicate they're working on
  the same task.
  """
  @spec find_pending_agent_with_any_ids(map()) :: Agent.t() | nil
  def find_pending_agent_with_any_ids(agent_attrs) do
    external_ids = Map.get(agent_attrs, :external_ids, %{})

    if Enum.empty?(external_ids) do
      nil
    else
      from(a in Agent, where: a.status == :pending)
      |> add_overlap_conditions(agent_attrs)
      |> Repo.one()
    end
  end

  @doc """
  Gets pending agents with overlapping external IDs for a given set of agent_attrs.
  """
  @spec list_pending_agents_with_overlapping_attrs(map()) :: [Agent.t()]
  def list_pending_agents_with_overlapping_attrs(agent_attrs) do
    from(a in Agent, where: a.status == :pending)
    |> add_overlap_conditions(agent_attrs)
    |> Repo.all()
  end

  # Message Management

  @doc """
  Creates a message for the given agent.

  Always calculates and sets the next sequential index, ignoring any provided index.

  ## Examples

      iex> create_message(agent_id, %{content: "Hello", type: :system})
      {:ok, %Message{}}

      iex> create_message(agent_id, %{content: nil, type: :system})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_message(binary(), map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def create_message(agent_id, attrs) do
    with {:ok, normalized_agent_id} <- normalize_agent_id(agent_id) do
      attrs_with_index = ensure_message_index(attrs, normalized_agent_id)
      attrs_with_agent = Map.put(attrs_with_index, :agent_id, normalized_agent_id)

      %Message{}
      |> Message.changeset(attrs_with_agent)
      |> Repo.insert()
    end
  end

  @doc """
  Returns the list of messages for a given agent ID, ordered by index ascending.

  ## Examples

      iex> messages(agent_id)
      [%Message{}, ...]

  """
  @spec messages(binary()) :: [Message.t()]
  def messages(agent_id) do
    with {:ok, normalized_agent_id} <- normalize_agent_id(agent_id) do
      from(m in Message, where: m.agent_id == ^normalized_agent_id, order_by: [asc: m.index])
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  Gets the next message index for an agent.

  Returns the highest existing index + 1, or 0 if no messages exist.
  """
  @spec get_next_message_index(binary()) :: non_neg_integer()
  def get_next_message_index(agent_id) do
    with {:ok, normalized_agent_id} <- normalize_agent_id(agent_id) do
      case from(m in Message,
             where: m.agent_id == ^normalized_agent_id,
             select: max(m.index)
           )
           |> Repo.one() do
        nil -> 0
        max_index -> max_index + 1
      end
    else
      :error -> 0
    end
  end

  # Private Helper Functions

  @spec get_user_organization_ids(User.t()) :: [binary()]
  defp get_user_organization_ids(user) do
    user
    |> Repo.preload(:organizations)
    |> Map.get(:organizations)
    |> Enum.map(& &1.id)
  end

  @spec build_user_agents_query([binary()]) :: Ecto.Query.t()
  defp build_user_agents_query(user_organization_ids) do
    from a in Agent,
      join: r in assoc(a, :repository),
      join: o in assoc(r, :organization),
      where: o.id in ^user_organization_ids
  end

  @spec apply_filters(Ecto.Query.t(), map()) :: Ecto.Query.t()
  defp apply_filters(query, params) do
    query
    |> apply_repository_name_filter(Map.get(params, "repository_name"))
    |> apply_organization_name_filter(Map.get(params, "organization_name"))
  end

  @spec apply_repository_name_filter(Ecto.Query.t(), binary() | nil) :: Ecto.Query.t()
  defp apply_repository_name_filter(query, repository_name)
       when is_binary(repository_name) and repository_name != "" do
    where(query, [_, r, _], r.name == ^repository_name)
  end

  defp apply_repository_name_filter(query, _), do: query

  @spec apply_organization_name_filter(Ecto.Query.t(), binary() | nil) :: Ecto.Query.t()
  defp apply_organization_name_filter(query, organization_name)
       when is_binary(organization_name) and organization_name != "" do
    where(query, [_, _, o], o.name == ^organization_name)
  end

  defp apply_organization_name_filter(query, _), do: query

  @spec validate_uuid(binary()) :: {:ok, binary()} | :error
  defp validate_uuid(id) do
    Ecto.UUID.cast(id)
  end

  @spec normalize_agent_id(binary()) :: {:ok, binary()} | :error
  defp normalize_agent_id(agent_id) do
    case Ecto.UUID.cast(agent_id) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> :error
    end
  end

  @spec ensure_message_index(map(), binary()) :: map()
  defp ensure_message_index(attrs, agent_id) do
    if Map.has_key?(attrs, :index) do
      attrs
    else
      Map.put(attrs, :index, get_next_message_index(agent_id))
    end
  end

  @spec add_overlap_conditions(Ecto.Query.t(), map()) :: Ecto.Query.t()
  defp add_overlap_conditions(query, agent_attrs) do
    external_ids = Map.get(agent_attrs, :external_ids, %{})
    
    []
    |> maybe_add_linear_condition(external_ids)
    |> maybe_add_github_issue_condition(external_ids)
    |> maybe_add_github_pr_condition(external_ids)
    |> maybe_add_slack_condition(external_ids)
    |> build_combined_conditions(query)
  end

  @spec maybe_add_linear_condition([any()], map()) :: [any()]
  defp maybe_add_linear_condition(conditions, external_ids) do
    case Map.get(external_ids, "linear_issue_id") do
      nil -> conditions
      linear_id ->
        condition = dynamic([a], fragment("?->>'linear_issue_id' = ?", a.external_ids, ^linear_id))
        [condition | conditions]
    end
  end

  @spec maybe_add_github_issue_condition([any()], map()) :: [any()]
  defp maybe_add_github_issue_condition(conditions, external_ids) do
    case Map.get(external_ids, "github_issue_id") do
      nil -> conditions
      github_id ->
        condition = dynamic([a], fragment("?->>'github_issue_id' = ?", a.external_ids, ^to_string(github_id)))
        [condition | conditions]
    end
  end

  @spec maybe_add_github_pr_condition([any()], map()) :: [any()]
  defp maybe_add_github_pr_condition(conditions, external_ids) do
    case Map.get(external_ids, "github_pull_request_id") do
      nil -> conditions
      pr_id ->
        condition = dynamic([a], fragment("?->>'github_pull_request_id' = ?", a.external_ids, ^to_string(pr_id)))
        [condition | conditions]
    end
  end

  @spec maybe_add_slack_condition([any()], map()) :: [any()]
  defp maybe_add_slack_condition(conditions, external_ids) do
    case Map.get(external_ids, "slack_thread_id") do
      nil -> conditions
      slack_id ->
        condition = dynamic([a], fragment("?->>'slack_thread_id' = ?", a.external_ids, ^slack_id))
        [condition | conditions]
    end
  end

  @spec build_combined_conditions([any()], Ecto.Query.t()) :: Ecto.Query.t()
  defp build_combined_conditions([], query), do: query
  defp build_combined_conditions([condition], query), do: where(query, ^condition)
  defp build_combined_conditions(conditions, query) do
    combined = Enum.reduce(conditions, fn condition, acc ->
      dynamic([], ^acc or ^condition)
    end)
    
    where(query, ^combined)
  end
end