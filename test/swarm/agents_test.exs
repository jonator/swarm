defmodule Swarm.AgentsTest do
  use Swarm.DataCase

  alias Swarm.Agents

  describe "agents" do
    alias Swarm.Agents.Agent

    import Swarm.AgentsFixtures

    @invalid_attrs %{
      name: nil,
      status: nil,
      type: nil,
      context: nil,
      started_at: nil,
      source: nil,
      external_ids: nil,
      completed_at: nil
    }

    test "list_agents/0 returns all agents" do
      agent = agent_fixture()
      assert Agents.list_agents() == [agent]
    end

    test "get_agent!/1 returns the agent with given id" do
      agent = agent_fixture()
      assert Agents.get_agent!(agent.id) == agent
    end

    test "create_agent/1 with valid data creates a agent" do
      valid_attrs = %{
        name: "some name",
        status: :pending,
        type: :researcher,
        context: "some context",
        started_at: ~U[2025-06-08 17:18:32.081174Z],
        source: :manual,
        external_ids: %{
          "github_pull_request_id" => "some github_pull_request_id",
          "github_issue_id" => "some github_issue_id",
          "linear_issue_id" => "some linear_issue_id",
          "linear_document_id" => "some linear_document_id",
          "slack_thread_id" => "some slack_thread_id"
        },
        completed_at: ~U[2025-06-08 17:18:32.081174Z]
      }

      assert {:ok, %Agent{} = agent} = Agents.create_agent(valid_attrs)
      assert agent.name == "some name"
      assert agent.status == :pending
      assert agent.type == :researcher
      assert agent.context == "some context"
      assert agent.started_at == ~U[2025-06-08 17:18:32Z]
      assert agent.source == :manual
      assert agent.external_ids["github_pull_request_id"] == "some github_pull_request_id"
      assert agent.external_ids["github_issue_id"] == "some github_issue_id"
      assert agent.external_ids["linear_issue_id"] == "some linear_issue_id"
      assert agent.external_ids["linear_document_id"] == "some linear_document_id"
      assert agent.external_ids["slack_thread_id"] == "some slack_thread_id"
      assert agent.completed_at == ~U[2025-06-08 17:18:32Z]
    end

    test "create_agent/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Agents.create_agent(@invalid_attrs)
    end

    test "update_agent/2 with valid data updates the agent" do
      agent = agent_fixture()

      update_attrs = %{
        name: "some updated name",
        status: :running,
        type: :coder,
        context: "some updated context",
        started_at: ~U[2025-06-08 17:18:32.081174Z],
        source: :linear,
        external_ids: %{
          "github_pull_request_id" => "some updated github_pull_request_id",
          "github_issue_id" => "some updated github_issue_id",
          "linear_issue_id" => "some updated linear_issue_id",
          "linear_document_id" => "some updated linear_document_id",
          "slack_thread_id" => "some updated slack_thread_id"
        },
        completed_at: ~U[2025-06-08 17:18:32.081174Z]
      }

      assert {:ok, %Agent{} = agent} = Agents.update_agent(agent, update_attrs)
      assert is_binary(agent.id)
      assert agent.name == "some updated name"
      assert agent.status == :running
      assert agent.type == :coder
      assert agent.context == "some updated context"
      assert agent.started_at == ~U[2025-06-08 17:18:32Z]
      assert agent.source == :linear
      assert agent.external_ids["github_pull_request_id"] == "some updated github_pull_request_id"
      assert agent.external_ids["github_issue_id"] == "some updated github_issue_id"
      assert agent.external_ids["linear_issue_id"] == "some updated linear_issue_id"
      assert agent.external_ids["linear_document_id"] == "some updated linear_document_id"
      assert agent.external_ids["slack_thread_id"] == "some updated slack_thread_id"
      assert agent.completed_at == ~U[2025-06-08 17:18:32Z]
    end

    test "update_agent/2 with invalid data returns error changeset" do
      agent = agent_fixture()
      assert {:error, %Ecto.Changeset{}} = Agents.update_agent(agent, @invalid_attrs)
      assert agent == Agents.get_agent!(agent.id)
    end

    test "delete_agent/1 deletes the agent" do
      agent = agent_fixture()
      assert {:ok, %Agent{}} = Agents.delete_agent(agent)
      assert_raise Ecto.NoResultsError, fn -> Agents.get_agent!(agent.id) end
    end

    test "change_agent/1 returns a agent changeset" do
      agent = agent_fixture()
      assert %Ecto.Changeset{} = Agents.change_agent(agent)
    end
  end
end
