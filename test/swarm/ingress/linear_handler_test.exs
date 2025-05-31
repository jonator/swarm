defmodule Swarm.Ingress.LinearHandlerTest do
  use Swarm.DataCase

  alias Swarm.Ingress.LinearHandler
  alias Swarm.Ingress.Event
  import Swarm.AccountsFixtures
  import Swarm.RepositoriesFixtures
  import Swarm.EventsFixtures

  # Helper function to create Linear access token for a user
  defp create_linear_token(user) do
    {:ok, _token} =
      Swarm.Accounts.save_token(user, %{
        token: "test_linear_token",
        expires_in: 3600,
        context: :linear,
        type: :access
      })
  end

  describe "handle/1" do
    setup do
      # Create unique user and repository for each test
      user =
        user_fixture(%{
          email: "test-#{:rand.uniform(10000)}@example.com",
          username: "test-user-#{:rand.uniform(10000)}"
        })

      # Create Linear access token for the user
      create_linear_token(user)

      repository =
        repository_fixture(user, %{
          name: "Test Repo",
          owner: user.username,
          external_id: "github:#{:rand.uniform(10000)}",
          linear_team_external_ids: ["2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"]
        })

      {:ok, user: user, repository: repository}
    end

    test "handles Linear issue assigned to swarm event", %{user: user} do
      params = linear_issue_assigned_to_swarm_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, agent} = LinearHandler.handle(event)
      assert agent.type == :researcher
      assert agent.source == :linear
      assert agent.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
      assert String.contains?(agent.name, "Linear Issue Research: Improve README")
      assert String.contains?(agent.context, "Linear Issue assigned: Improve README")
    end

    test "handles Linear issue description mention event", %{user: user} do
      params = linear_issue_description_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, agent} = LinearHandler.handle(event)
      assert agent.type == :researcher
      assert agent.source == :linear
      assert agent.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
      assert String.contains?(agent.name, "Linear Issue Analysis: Improve README")

      assert String.contains?(
               agent.context,
               "Linear Issue mentioned in description: Improve README"
             )
    end

    test "handles Linear comment mention event", %{user: user} do
      params = linear_issue_comment_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, agent} = LinearHandler.handle(event)
      assert agent.type == :researcher
      assert agent.source == :linear
      assert agent.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
      assert String.contains?(agent.name, "Linear Comment Response: Improve README")
      assert String.contains?(agent.context, "Linear Comment Mention in Issue: Improve README")
      assert String.contains?(agent.context, "This is a mention comment @swarmdev")
    end

    test "rejects non-Linear events" do
      github_event = %Event{
        source: :github,
        type: "pull_request",
        raw_data: %{},
        user_id: nil,
        repository_external_id: nil,
        external_ids: %{},
        context: %{},
        timestamp: DateTime.utc_now()
      }

      assert {:error, message} = LinearHandler.handle(github_event)
      assert String.contains?(message, "LinearHandler received non-Linear event: github")
    end
  end

  describe "should_spawn_agent?/1" do
    test "returns true for issue assigned to swarm" do
      params = linear_issue_assigned_to_swarm_params()
      {:ok, event} = Event.new(params, :linear)

      assert LinearHandler.should_spawn_agent?(event) == true
    end

    test "returns true for description mention" do
      params = linear_issue_description_mention_params()
      {:ok, event} = Event.new(params, :linear)

      assert LinearHandler.should_spawn_agent?(event) == true
    end

    test "returns true for comment mention" do
      params = linear_issue_comment_mention_params()
      {:ok, event} = Event.new(params, :linear)

      assert LinearHandler.should_spawn_agent?(event) == true
    end

    test "returns false for unknown event types" do
      event = %Event{
        source: :linear,
        type: "unknown_event",
        raw_data: %{},
        user_id: nil,
        repository_external_id: nil,
        external_ids: %{},
        context: %{},
        timestamp: DateTime.utc_now()
      }

      assert LinearHandler.should_spawn_agent?(event) == false
    end

    test "returns true for document mention" do
      params = linear_document_mention()
      {:ok, event} = Event.new(params, :linear)

      assert LinearHandler.should_spawn_agent?(event) == true
    end
  end

  describe "find_repository_for_linear_event/2" do
    setup do
      user =
        user_fixture(%{
          email: "test-repo-#{:rand.uniform(10000)}@example.com",
          username: "test-repo-user-#{:rand.uniform(10000)}"
        })

      {:ok, user: user}
    end

    test "finds repository by team ID mapping", %{user: user} do
      repository =
        repository_fixture(user, %{
          name: "Swarm Repo",
          owner: user.username,
          external_id: "github:#{:rand.uniform(10000)}",
          linear_team_external_ids: ["2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"]
        })

      # Create event with matching team ID
      params = linear_issue_assigned_to_swarm_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, found_repo} = LinearHandler.find_repository_for_linear_event(user, event)
      assert found_repo.id == repository.id
    end

    test "returns error when no team mapping exists", %{user: user} do
      # Create repository without matching team ID
      _repo =
        repository_fixture(user, %{
          name: "Test Repo",
          owner: user.username,
          external_id: "github:#{:rand.uniform(10000)}",
          linear_team_external_ids: ["different-team-id"]
        })

      params = linear_issue_assigned_to_swarm_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:error,
              "No repository found with Linear team ID: 2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"} =
               LinearHandler.find_repository_for_linear_event(user, event)
    end

    test "returns error when user has no repositories", %{user: user} do
      params = linear_issue_assigned_to_swarm_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:error, "No repositories found for user"} =
               LinearHandler.find_repository_for_linear_event(user, event)
    end
  end

  describe "build_agent_attributes/3" do
    setup do
      user =
        user_fixture(%{
          email: "test-attr-#{:rand.uniform(10000)}@example.com",
          username: "test-attr-user-#{:rand.uniform(10000)}"
        })

      repository =
        repository_fixture(user, %{
          name: "Test Repo",
          owner: user.username,
          external_id: "github:#{:rand.uniform(10000)}",
          linear_team_external_ids: ["2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"]
        })

      {:ok, user: user, repository: repository}
    end

    test "builds correct attributes for issue assigned event", %{
      user: user,
      repository: repository
    } do
      params = linear_issue_assigned_to_swarm_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

      assert attrs.user_id == user.id
      assert attrs.repository_id == repository.id
      assert attrs.source == :linear
      assert attrs.status == :pending
      assert attrs.type == :researcher
      assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
      assert String.contains?(attrs.name, "Linear Issue Research: Improve README")
      assert String.contains?(attrs.context, "Linear Issue assigned: Improve README")
    end

    test "builds correct attributes for comment mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_issue_comment_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

      assert attrs.user_id == user.id
      assert attrs.repository_id == repository.id
      assert attrs.source == :linear
      assert attrs.status == :pending
      assert attrs.type == :researcher
      assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
      assert String.contains?(attrs.name, "Linear Comment Response: Improve README")
      assert String.contains?(attrs.context, "This is a mention comment @swarmdev")
    end

    test "detects implementation plan and creates coder agent", %{
      user: user,
      repository: repository
    } do
      # Create params with implementation keywords
      params = linear_issue_assigned_to_swarm_params()

      # Modify the description to include implementation plan
      updated_params =
        put_in(params, ["notification", "issue", "description"], """
        Implementation plan:
        Step 1: Update README.md file
        Step 2: Add new sections for installation
        Step 3: Add usage examples
        """)

      {:ok, event} = Event.new(updated_params, :linear, user_id: user.id)

      assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

      assert attrs.type == :coder
      assert String.contains?(attrs.name, "Linear Issue Implementation: Improve README")
    end

    test "builds correct attributes for description mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_issue_description_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

      assert attrs.user_id == user.id
      assert attrs.repository_id == repository.id
      assert attrs.source == :linear
      assert attrs.status == :pending
      assert attrs.type == :researcher
      assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
      assert String.contains?(attrs.name, "Linear Issue Analysis: Improve README")
      assert String.contains?(attrs.context, "@swarmdev")
    end

    test "builds correct attributes for document mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_document_mention()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

      assert attrs.user_id == user.id
      assert attrs.repository_id == repository.id
      assert attrs.source == :linear
      assert attrs.status == :pending
      assert attrs.type == :researcher
      assert String.contains?(attrs.name, "Linear Document Response: Test doc")
      assert String.contains?(attrs.context, "Linear Document Mention")
    end
  end

  describe "helper functions" do
    test "detects swarm assignee correctly" do
      # Test with swarm in name - issueAssignedToYou events always spawn
      params_with_swarm = linear_issue_assigned_to_swarm_params()
      {:ok, event_with_swarm} = Event.new(params_with_swarm, :linear)

      assert LinearHandler.should_spawn_agent?(event_with_swarm) == true

      # Note: For the new notification format, issueAssignedToYou webhook events
      # are only sent when the issue is assigned to the authenticated app user (Swarm),
      # so we always spawn agents for these events
    end

    test "detects @swarm mentions in text" do
      # Test comment mention detection
      params = linear_issue_comment_mention_params()
      {:ok, event} = Event.new(params, :linear)

      assert LinearHandler.should_spawn_agent?(event) == true

      # Test description mention detection
      params = linear_issue_description_mention_params()
      {:ok, event} = Event.new(params, :linear)

      assert LinearHandler.should_spawn_agent?(event) == true
    end

    test "extracts implementation plan indicators" do
      # Test issue with implementation keywords
      implementation_description = """
      Implementation plan:
      Step 1: Create new component
      Step 2: Add to main file
      TODO: Add tests
      """

      event = %Event{
        source: :linear,
        type: "issueAssignedToYou",
        raw_data: %{},
        user_id: nil,
        repository_external_id: nil,
        external_ids: %{},
        context: %{
          notification: %{
            "issue" => %{
              "title" => "Add new feature",
              "description" => implementation_description,
              "assignee" => %{"name" => "swarm"}
            }
          }
        },
        timestamp: DateTime.utc_now()
      }

      assert LinearHandler.should_spawn_agent?(event) == true
    end
  end
end
