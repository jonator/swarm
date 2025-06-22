defmodule Swarm.AgentsTest do
  use Swarm.DataCase

  alias Swarm.Agents
  alias Swarm.Organizations
  import Swarm.AgentsFixtures
  import Swarm.AccountsFixtures
  import Swarm.RepositoriesFixtures

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
      assert agent.started_at == ~N[2025-06-08 17:18:32]
      assert agent.source == :manual
      assert agent.external_ids["github_pull_request_id"] == "some github_pull_request_id"
      assert agent.external_ids["github_issue_id"] == "some github_issue_id"
      assert agent.external_ids["linear_issue_id"] == "some linear_issue_id"
      assert agent.external_ids["linear_document_id"] == "some linear_document_id"
      assert agent.external_ids["slack_thread_id"] == "some slack_thread_id"
      assert agent.completed_at == ~N[2025-06-08 17:18:32]
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
        started_at: ~N[2025-06-08 17:18:32],
        source: :linear,
        external_ids: %{
          "github_pull_request_id" => "some updated github_pull_request_id",
          "github_issue_id" => "some updated github_issue_id",
          "linear_issue_id" => "some updated linear_issue_id",
          "linear_document_id" => "some updated linear_document_id",
          "slack_thread_id" => "some updated slack_thread_id"
        },
        completed_at: ~N[2025-06-08 17:18:32]
      }

      assert {:ok, %Agent{} = agent} = Agents.update_agent(agent, update_attrs)
      assert is_binary(agent.id)
      assert agent.name == "some updated name"
      assert agent.status == :running
      assert agent.type == :coder
      assert agent.context == "some updated context"
      assert agent.started_at == ~N[2025-06-08 17:18:32]
      assert agent.source == :linear
      assert agent.external_ids["github_pull_request_id"] == "some updated github_pull_request_id"
      assert agent.external_ids["github_issue_id"] == "some updated github_issue_id"
      assert agent.external_ids["linear_issue_id"] == "some updated linear_issue_id"
      assert agent.external_ids["linear_document_id"] == "some updated linear_document_id"
      assert agent.external_ids["slack_thread_id"] == "some updated slack_thread_id"
      assert agent.completed_at == ~N[2025-06-08 17:18:32]
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

  describe "list_agents/2" do
    setup do
      user = user_fixture()
      repo1 = repository_fixture(user, %{name: "repo1", owner: user.username})
      repo2 = repository_fixture(user, %{name: "repo2", owner: user.username})
      {:ok, other_org} = Organizations.get_or_create_organization(user, "other_org", 123_456)
      repo3 = repository_fixture(other_org, %{name: "repo3", owner: other_org.name})
      repo4 = repository_fixture(other_org, %{name: "repo1", owner: other_org.name})

      agent1 = agent_fixture(%{repository_id: repo1.id})
      agent2 = agent_fixture(%{repository_id: repo2.id})
      agent3 = agent_fixture(%{repository_id: repo3.id})
      agent4 = agent_fixture(%{repository_id: repo4.id})
      agent5 = agent_fixture(%{repository_id: repo1.id})
      agent6 = agent_fixture(%{repository_id: repo3.id})
      agent7 = agent_fixture(%{repository_id: repo3.id})

      # This agent should not be in the list for `user`
      other_user = user_fixture(%{username: "another-user"})

      other_user_repo =
        repository_fixture(other_user, %{name: "other_user_repo", owner: other_user.username})

      _agent_for_other_user = agent_fixture(%{repository_id: other_user_repo.id})

      %{
        user: user,
        other_org: other_org,
        agents: [agent1, agent2, agent3, agent4, agent5, agent6, agent7]
      }
    end

    test "with no params returns all user agents", %{
      user: user,
      agents: [agent1, agent2, agent3, agent4, agent5, agent6, agent7]
    } do
      agents = Agents.list_agents(user, %{})
      assert length(agents) == 7
      assert agent1 in agents
      assert agent2 in agents
      assert agent3 in agents
      assert agent4 in agents
      assert agent5 in agents
      assert agent6 in agents
      assert agent7 in agents
    end

    test "with organization_name param returns agents for that organization", %{
      user: user,
      other_org: other_org,
      agents: [agent1, agent2, agent3, agent4, agent5, agent6, agent7]
    } do
      agents = Agents.list_agents(user, %{"organization_name" => other_org.name})
      assert length(agents) == 4
      assert agent3 in agents
      assert agent4 in agents
      assert agent6 in agents
      assert agent7 in agents
      assert agent1 not in agents
      assert agent2 not in agents
      assert agent5 not in agents
    end

    test "with repository_name param returns agents for that repository", %{
      user: user,
      agents: [agent1, _, _, agent4, agent5, _, _]
    } do
      agents = Agents.list_agents(user, %{"repository_name" => "repo1"})
      assert length(agents) == 3
      assert agent1 in agents
      assert agent4 in agents
      assert agent5 in agents
    end

    test "with organization_name and repository_name returns agents for that repo in that org", %{
      user: user,
      other_org: other_org,
      agents: [agent1, _, agent3, agent4, _, agent6, agent7]
    } do
      agents_for_repo_in_org =
        Agents.list_agents(user, %{
          "organization_name" => other_org.name,
          "repository_name" => "repo1"
        })

      assert length(agents_for_repo_in_org) == 1
      assert agent4 in agents_for_repo_in_org
      assert agent1 not in agents_for_repo_in_org

      agents_for_other_repo_in_org =
        Agents.list_agents(user, %{
          "organization_name" => other_org.name,
          "repository_name" => "repo3"
        })

      assert length(agents_for_other_repo_in_org) == 3
      assert agent3 in agents_for_other_repo_in_org
      assert agent6 in agents_for_other_repo_in_org
      assert agent7 in agents_for_other_repo_in_org
    end
  end
end
