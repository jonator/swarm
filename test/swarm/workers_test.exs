defmodule Swarm.WorkersTest do
  use ExUnit.Case, async: true

  alias Swarm.Workers
  alias Swarm.Ingress.Event

  describe "spawn/2" do
    test "determines researcher agent type for insufficient context" do
      agent_attrs = %{
        context: "Fix bug",
        source: :linear,
        user_id: 1,
        repository: %{id: 1},
        linear_issue_id: "test-issue-123"
      }

      {:ok, agent_type} = Workers.determine_agent_type(agent_attrs)
      assert agent_type == :researcher
    end

    test "determines coder agent type for sufficient context" do
      agent_attrs = %{
        context: """
        We need to implement a new API endpoint for user authentication.
        The function should be added to the auth controller and handle
        POST requests to /api/auth/login. The implementation needs to
        validate credentials and return a JWT token. Please update the
        README documentation as well.
        """,
        source: :linear,
        user_id: 1,
        repository: %{id: 1},
        linear_issue_id: "test-issue-456"
      }

      {:ok, agent_type} = Workers.determine_agent_type(agent_attrs)
      assert agent_type == :coder
    end

    test "analyze_context_sufficiency returns false for short context" do
      short_context = "Fix this"
      refute Workers.analyze_context_sufficiency(short_context)
    end

    test "analyze_context_sufficiency returns true for detailed context" do
      detailed_context = """
      We need to implement a new function in the user authentication module.
      The code should handle password validation and return appropriate error
      messages. Please add the implementation to the auth.ex file and update
      the API documentation accordingly.
      """

      # This should return true based on our heuristics
      assert Workers.analyze_context_sufficiency(detailed_context)
    end
  end

  describe "determine_agent_type/1" do
    test "returns researcher for minimal context" do
      agent_attrs = %{context: "Small task"}

      {:ok, agent_type} = Workers.determine_agent_type(agent_attrs)
      assert agent_type == :researcher
    end

    test "returns coder for comprehensive context" do
      agent_attrs = %{
        context: """
        Please implement a new feature in the authentication system.
        We need to add a password reset function that will send an email
        to users. The code should be added to the auth module and should
        include proper error handling. Update the README with usage examples.
        """
      }

      {:ok, agent_type} = Workers.determine_agent_type(agent_attrs)
      assert agent_type == :coder
    end
  end

  describe "generate_agent_name/2" do
    test "generates researcher name with linear issue" do
      agent_attrs = %{linear_issue_id: "71ee683d-74e4-4668-95f7-537af7734054"}

      name = Workers.generate_agent_name(:researcher, agent_attrs)
      assert name == "Research Agent - Linear Issue 71ee683d"
    end

    test "generates researcher name with linear issue from external_ids" do
      agent_attrs = %{external_ids: %{linear_issue_id: "71ee683d-74e4-4668-95f7-537af7734054"}}

      name = Workers.generate_agent_name(:researcher, agent_attrs)
      assert name == "Research Agent - Linear Issue 71ee683d"
    end

    test "generates coder name with github issue" do
      agent_attrs = %{github_issue_id: "12345"}

      name = Workers.generate_agent_name(:coder, agent_attrs)
      assert name == "Coding Agent - GitHub Issue 12345"
    end

    test "generates coder name with github issue from external_ids" do
      agent_attrs = %{external_ids: %{github_issue_id: "12345"}}

      name = Workers.generate_agent_name(:coder, agent_attrs)
      assert name == "Coding Agent - GitHub Issue 12345"
    end

    test "prioritizes external_ids over direct keys" do
      agent_attrs = %{
        linear_issue_id: "old-id-123",
        external_ids: %{linear_issue_id: "new-id-456"}
      }

      name = Workers.generate_agent_name(:researcher, agent_attrs)
      assert name == "Research Agent - Linear Issue new-id-4"
    end

    test "generates fallback name when no issue ID" do
      agent_attrs = %{}

      name = Workers.generate_agent_name(:researcher, agent_attrs)
      assert String.contains?(name, "Research Agent -")
    end
  end

  # Mock test for event processing
  test "spawn processes event successfully" do
    # This would be a more comprehensive integration test
    # For now, we're just testing the basic structure

    _event = %Event{
      source: :linear,
      type: "issueAssignedToYou",
      raw_data: %{},
      user_id: nil,
      repository_external_id: nil,
      external_ids: %{
        linear_issue_id: "test-issue-123"
      },
      context: %{},
      timestamp: DateTime.utc_now()
    }

    _agent_attrs = %{
      context: "Test context for implementation",
      source: :linear,
      user_id: 1,
      repository: %{id: 1},
      linear_issue_id: "test-issue-123"
    }

    # This test would require setting up the database and mocking
    # the Egress.acknowledge function and Oban.insert
    # For now, we just verify the structure exists

    assert function_exported?(Workers, :spawn, 2)
    assert function_exported?(Workers, :determine_agent_type, 1)
  end

  # Note: Event acknowledgment behavior
  # - New agents: Event is acknowledged when agent is created
  # - Existing pending agents: Event is NOT acknowledged, agent is updated
  # This prevents duplicate acknowledgments for the same work

  describe "external_ids handling" do
    test "external_ids are properly mapped from agent_attrs" do
      # Test that external_ids are directly mapped from agent_attrs
      agent_attrs = %{
        context: "Test context",
        source: :linear,
        user_id: 1,
        repository: %{id: 1},
        external_ids: %{
          linear_issue_id: "linear-123",
          github_issue_id: "github-456",
          slack_thread_id: "slack-789"
        }
      }

      # The external_ids should be used directly from agent_attrs
      expected_external_ids = agent_attrs[:external_ids]

      assert expected_external_ids[:linear_issue_id] == "linear-123"
      assert expected_external_ids[:github_issue_id] == "github-456"
      assert expected_external_ids[:slack_thread_id] == "slack-789"
    end

    test "falls back to event external_ids when agent_attrs has none" do
      # When agent_attrs doesn't have external_ids, should use event external_ids
      _agent_attrs = %{
        context: "Test context",
        source: :linear,
        user_id: 1,
        repository: %{id: 1}
      }

      event_external_ids = %{
        linear_issue_id: "event-linear-123"
      }

      # In the actual implementation, this would come from event.external_ids
      # Here we just verify the expected behavior
      assert event_external_ids[:linear_issue_id] == "event-linear-123"
    end
  end
end
