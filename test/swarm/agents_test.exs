defmodule Swarm.AgentsTest do
  use Swarm.DataCase

  alias Swarm.Agents
  import Swarm.AgentsFixtures

  describe "agents" do
    alias Swarm.Agents.Agent

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

  describe "find_pending_agent_with_any_ids/1" do
    test "finds pending agent with matching linear_issue_id" do
      existing_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"linear_issue_id" => "issue-123", "linear_app_user_id" => "user-456"}
        })

      agent_attrs = %{external_ids: %{"linear_issue_id" => "issue-123"}}

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == existing_agent
    end

    test "finds pending agent with matching github_issue_id" do
      existing_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"github_issue_id" => "gh-issue-789"}
        })

      agent_attrs = %{external_ids: %{"github_issue_id" => "gh-issue-789"}}

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == existing_agent
    end

    test "finds pending agent with matching github_pull_request_id" do
      existing_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"github_pull_request_id" => "pr-456"}
        })

      agent_attrs = %{external_ids: %{"github_pull_request_id" => "pr-456"}}

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == existing_agent
    end

    test "finds pending agent with matching slack_thread_id" do
      existing_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"slack_thread_id" => "thread-789"}
        })

      agent_attrs = %{external_ids: %{"slack_thread_id" => "thread-789"}}

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == existing_agent
    end

    test "returns nil when no matching IDs found" do
      agent_fixture(%{
        status: :pending,
        external_ids: %{"linear_issue_id" => "different-issue"}
      })

      agent_attrs = %{external_ids: %{"linear_issue_id" => "non-matching-issue"}}

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == nil
    end

    test "returns nil when agent exists but is not pending" do
      agent_fixture(%{
        status: :completed,
        external_ids: %{"linear_issue_id" => "issue-123"}
      })

      agent_attrs = %{external_ids: %{"linear_issue_id" => "issue-123"}}

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == nil
    end

    test "returns nil when external_ids is missing" do
      agent_fixture(%{status: :pending})

      agent_attrs = %{external_ids: %{"linear_issue_id" => "issue-123"}}

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == nil
    end

    test "returns nil when agent_attrs has no external_ids" do
      agent_fixture(%{
        status: :pending,
        external_ids: %{"linear_issue_id" => "issue-123"}
      })

      agent_attrs = %{}

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == nil
    end

    test "finds agent with multiple matching IDs" do
      existing_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{
            "linear_issue_id" => "issue-123",
            "github_issue_id" => "gh-issue-456"
          }
        })

      agent_attrs = %{
        external_ids: %{
          "linear_issue_id" => "issue-123",
          "github_issue_id" => "gh-issue-456"
        }
      }

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == existing_agent
    end

    test "finds agent when only one ID matches among multiple" do
      existing_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"linear_issue_id" => "issue-123"}
        })

      agent_attrs = %{
        external_ids: %{
          "linear_issue_id" => "issue-123",
          "github_issue_id" => "different-gh-issue"
        }
      }

      assert Agents.find_pending_agent_with_any_ids(agent_attrs) == existing_agent
    end
  end

  describe "list_pending_agents_with_overlapping_attrs/1" do
    test "returns all pending agents with matching linear_issue_id" do
      agent1 =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"linear_issue_id" => "issue-123"}
        })

      agent2 =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"linear_issue_id" => "issue-123"}
        })

      # Non-matching agent
      agent_fixture(%{
        status: :pending,
        external_ids: %{"linear_issue_id" => "different-issue"}
      })

      agent_attrs = %{external_ids: %{"linear_issue_id" => "issue-123"}}

      result = Agents.list_pending_agents_with_overlapping_attrs(agent_attrs)
      assert length(result) == 2
      assert agent1 in result
      assert agent2 in result
    end

    test "returns empty list when no matching agents found" do
      agent_fixture(%{
        status: :pending,
        external_ids: %{"linear_issue_id" => "different-issue"}
      })

      agent_attrs = %{external_ids: %{"linear_issue_id" => "non-matching-issue"}}

      assert Agents.list_pending_agents_with_overlapping_attrs(agent_attrs) == []
    end

    test "only returns pending agents" do
      agent_fixture(%{
        status: :completed,
        external_ids: %{"linear_issue_id" => "issue-123"}
      })

      agent_fixture(%{
        status: :failed,
        external_ids: %{"linear_issue_id" => "issue-123"}
      })

      pending_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"linear_issue_id" => "issue-123"}
        })

      agent_attrs = %{external_ids: %{"linear_issue_id" => "issue-123"}}

      result = Agents.list_pending_agents_with_overlapping_attrs(agent_attrs)
      assert result == [pending_agent]
    end

    test "returns agents matching any of multiple ID types" do
      linear_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"linear_issue_id" => "issue-123"}
        })

      github_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"github_issue_id" => "gh-issue-456"}
        })

      slack_agent =
        agent_fixture(%{
          status: :pending,
          external_ids: %{"slack_thread_id" => "thread-789"}
        })

      agent_attrs = %{
        external_ids: %{
          "linear_issue_id" => "issue-123",
          "github_issue_id" => "gh-issue-456",
          "slack_thread_id" => "thread-789"
        }
      }

      result = Agents.list_pending_agents_with_overlapping_attrs(agent_attrs)
      assert length(result) == 3
      assert linear_agent in result
      assert github_agent in result
      assert slack_agent in result
    end
  end
end
