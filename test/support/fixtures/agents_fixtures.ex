defmodule Swarm.AgentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Agents` context.
  """

  @doc """
  Generate a agent.
  """
  def agent_fixture(attrs \\ %{}) do
    {:ok, agent} =
      attrs
      |> Enum.into(%{
        completed_at: ~N[2025-05-26 01:07:00],
        context: "some context",
        github_issue_id: "some github_issue_id",
        github_pull_request_id: "some github_pull_request_id",
        linear_issue_id: "some linear_issue_id",
        name: "some name",
        slack_thread_id: "some slack_thread_id",
        started_at: ~N[2025-05-26 01:07:00],
        status: :pending,
        trigger: :frontend,
        trigger_source_id: "some trigger_source_id",
        type: :researcher
      })
      |> Swarm.Agents.create_agent()

    agent
  end
end
