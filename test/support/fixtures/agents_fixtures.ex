defmodule Swarm.AgentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Agents` context.
  """

  import Swarm.RepositoriesFixtures

  @doc """
  Generate a agent.
  """
  def agent_fixture(attrs \\ %{}) do
    user = Map.fetch!(attrs, :user)

    attrs =
      attrs
      |> Map.put_new(:user_id, user.id)
      |> Map.put_new(:repository_id, repository_fixture(user).id)

    {:ok, agent} =
      attrs
      |> Enum.into(%{
        completed_at: ~N[2025-05-26 01:07:00],
        context: "some context",
        external_ids: %{
          "github_issue_id" => "some github_issue_id",
          "github_pull_request_id" => "some github_pull_request_id",
          "linear_issue_id" => "some linear_issue_id",
          "slack_thread_id" => "some slack_thread_id"
        },
        name: "some name",
        started_at: ~N[2025-05-26 01:07:00],
        status: :pending,
        source: :manual,
        type: :researcher
      })
      |> Swarm.Agents.create_agent()

    agent
  end
end
