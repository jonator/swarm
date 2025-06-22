defmodule Swarm.Agents do
  @moduledoc """
  The Agents context.
  """

  import Ecto.Query, warn: false
  alias Swarm.Repo

  alias Swarm.Agents.Agent
  alias Swarm.Accounts.User

  @doc """
  Returns the list of agents.

  ## Examples

      iex> list_agents()
      [%Agent{}, ...]

  """
  def list_agents do
    Repo.all(Agent)
  end

  def list_agents(%User{} = user, params \\ %{}) do
    user_organization_ids =
      user
      |> Repo.preload(:organizations)
      |> Map.get(:organizations)
      |> Enum.map(& &1.id)

    # Base query for agents accessible by the user
    query =
      from a in Agent,
        join: r in assoc(a, :repository),
        join: o in assoc(r, :organization),
        where: o.id in ^user_organization_ids

    # Apply filters from params
    query
    |> apply_filters(params)
    |> Repo.all()
  end

  defp apply_filters(query, params) do
    query
    |> apply_repository_name_filter(Map.get(params, "repository_name"))
    |> apply_organization_name_filter(Map.get(params, "organization_name"))
  end

  defp apply_repository_name_filter(query, repository_name)
       when is_binary(repository_name) and repository_name != "" do
    where(query, [_, r, _], r.name == ^repository_name)
  end

  defp apply_repository_name_filter(query, _), do: query

  defp apply_organization_name_filter(query, organization_name)
       when is_binary(organization_name) and organization_name != "" do
    where(query, [_, _, o], o.name == ^organization_name)
  end

  defp apply_organization_name_filter(query, _), do: query

  @doc """
  Gets a single agent.

  Raises `Ecto.NoResultsError` if the Agent does not exist.

  ## Examples

      iex> get_agent!(123)
      %Agent{}

      iex> get_agent!(456)
      ** (Ecto.NoResultsError)

  """
  def get_agent!(id), do: Repo.get!(Agent, id)

  @doc """
  Gets a single agent.

  Returns `nil` if the Agent does not exist.

  ## Examples

      iex> get_agent!(123)
      %Agent{}

      iex> get_agent!(456)
      ** (Ecto.NoResultsError)

  """
  def get_agent(id), do: Repo.get(Agent, id)

  @doc """
  Creates a agent.

  ## Examples

      iex> create_agent(%{field: value})
      {:ok, %Agent{}}

      iex> create_agent(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_agent(attrs \\ %{}) do
    %Agent{}
    |> Agent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a agent.

  ## Examples

      iex> update_agent(agent, %{field: new_value})
      {:ok, %Agent{}}

      iex> update_agent(agent, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_agent(%Agent{} = agent, attrs) do
    agent
    |> Agent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a agent.

  ## Examples

      iex> delete_agent(agent)
      {:ok, %Agent{}}

      iex> delete_agent(agent)
      {:error, %Ecto.Changeset{}}

  """
  def delete_agent(%Agent{} = agent) do
    Repo.delete(agent)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking agent changes.

  ## Examples

      iex> change_agent(agent)
      %Ecto.Changeset{data: %Agent{}}

  """
  def change_agent(%Agent{} = agent, attrs \\ %{}) do
    Agent.changeset(agent, attrs)
  end

  @doc """
  Finds an agent that has overlapping agent_attrs IDs.

  This checks for agents with the same Linear issue ID, GitHub issue ID,
  or other identifying attributes that would indicate they're working on
  the same task.
  """
  def find_pending_agent_with_any_ids(agent_attrs) do
    external_ids = Map.get(agent_attrs, :external_ids, %{})

    # Return nil if there are no external IDs to search for
    if Enum.empty?(external_ids) do
      nil
    else
      query = from(a in Agent, where: a.status == :pending)

      # Add conditions for overlapping IDs
      query = add_overlap_conditions(query, agent_attrs)

      Repo.one(query)
    end
  end

  defp add_overlap_conditions(query, agent_attrs) do
    external_ids = Map.get(agent_attrs, :external_ids, %{})
    conditions = []

    # Check Linear issue ID
    conditions =
      if linear_id = Map.get(external_ids, "linear_issue_id") do
        [
          dynamic([a], fragment("?->>'linear_issue_id' = ?", a.external_ids, ^linear_id))
          | conditions
        ]
      else
        conditions
      end

    # Check GitHub issue ID
    conditions =
      if github_id = Map.get(external_ids, "github_issue_id") do
        [
          dynamic(
            [a],
            fragment("?->>'github_issue_id' = ?", a.external_ids, ^to_string(github_id))
          )
          | conditions
        ]
      else
        conditions
      end

    # Check GitHub PR ID
    conditions =
      if pr_id = Map.get(external_ids, "github_pull_request_id") do
        [
          dynamic(
            [a],
            fragment(
              "?->>'github_pull_request_id' = ?",
              a.external_ids,
              ^to_string(pr_id)
            )
          )
          | conditions
        ]
      else
        conditions
      end

    # Check Slack thread ID
    conditions =
      if slack_id = Map.get(external_ids, "slack_thread_id") do
        [
          dynamic([a], fragment("?->>'slack_thread_id' = ?", a.external_ids, ^slack_id))
          | conditions
        ]
      else
        conditions
      end

    # Combine conditions with OR
    case conditions do
      [] ->
        query

      [condition] ->
        where(query, ^condition)

      conditions ->
        combined =
          Enum.reduce(conditions, fn condition, acc ->
            dynamic([], ^acc or ^condition)
          end)

        where(query, ^combined)
    end
  end

  @doc """
  Marks an agent as started by setting started_at to now and status to running.
  """
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
  def mark_agent_completed(%Agent{} = agent) do
    update_agent(agent, %{
      status: :completed,
      completed_at: NaiveDateTime.utc_now()
    })
  end

  @doc """
  Marks an agent as failed by setting status to failed.
  """
  def mark_agent_failed(%Agent{} = agent) do
    update_agent(agent, %{status: :failed})
  end

  @doc """
  Gets agents by status.
  """
  def list_agents_by_status(status) when status in [:pending, :running, :completed, :failed] do
    from(a in Agent, where: a.status == ^status)
    |> Repo.all()
  end

  @doc """
  Gets pending agents with overlapping external IDs for a given set of agent_attrs.
  """
  def list_pending_agents_with_overlapping_attrs(agent_attrs) do
    query = from(a in Agent, where: a.status == :pending)
    query = add_overlap_conditions(query, agent_attrs)
    Repo.all(query)
  end
end
