defmodule Swarm.Ingress.EventTest do
  use ExUnit.Case, async: true

  alias Swarm.Ingress.Event
  alias Swarm.LinearEventsFixtures
  alias Swarm.GitHubEventsFixtures

  describe "new/3 with Linear events" do
    test "creates event from linear issue description mention" do
      event_data = LinearEventsFixtures.linear_issue_description_mention_params()

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.source == :linear
      assert event.type == "issueMention"
      assert event.raw_data == event_data
      assert event.user_id == nil
      assert event.repository_external_id == nil

      # Verify external IDs extraction
      assert event.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"
      assert event.external_ids["linear_team_id"] == "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"
      assert event.external_ids["linear_app_user_id"] == "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
      refute Map.has_key?(event.external_ids, "linear_comment_id")
      refute Map.has_key?(event.external_ids, "linear_document_id")

      # Verify context extraction
      assert event.context.action == "issueMention"
      assert event.context.organization_id == "4fde7f37-de48-4d5c-93fb-473c8f24d4cb"
      assert event.context.webhook_id == "d86e55d2-acb2-4ba5-bdc5-78368417c3a8"
      assert event.context.webhook_timestamp == 1_748_718_589_311
      assert event.context.actor["id"] == "f15f0e68-9424-4add-b7c6-1d318e455719"
      assert event.context.actor["email"] == "jonathanator0@gmail.com"
      assert event.context.actor["name"] == "Jonathan Ator"
      assert event.context.notification["type"] == "issueMention"
      assert event.context.notification["issue"]["identifier"] == "SW-10"
      assert event.context.notification["issue"]["title"] == "Improve README"
    end

    test "creates event from linear issue assigned to swarm" do
      event_data = LinearEventsFixtures.linear_issue_assigned_to_swarm_params()

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.source == :linear
      assert event.type == "issueAssignedToYou"
      assert event.raw_data == event_data

      # Verify external IDs extraction
      assert event.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"
      assert event.external_ids["linear_team_id"] == "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"
      assert event.external_ids["linear_app_user_id"] == "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
      refute Map.has_key?(event.external_ids, "linear_comment_id")
      refute Map.has_key?(event.external_ids, "linear_document_id")

      # Verify context extraction
      assert event.context.action == "issueAssignedToYou"
      assert event.context.organization_id == "4fde7f37-de48-4d5c-93fb-473c8f24d4cb"
      assert event.context.webhook_id == "d86e55d2-acb2-4ba5-bdc5-78368417c3a8"
      assert event.context.webhook_timestamp == 1_748_718_790_250
      assert event.context.actor["id"] == "f15f0e68-9424-4add-b7c6-1d318e455719"
      assert event.context.notification["type"] == "issueAssignedToYou"
      assert event.context.notification["issue"]["identifier"] == "SW-10"
    end

    test "creates event from linear issue comment mention" do
      event_data = LinearEventsFixtures.linear_issue_comment_mention_params()

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.source == :linear
      assert event.type == "issueCommentMention"
      assert event.raw_data == event_data

      # Verify external IDs extraction
      assert event.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"
      assert event.external_ids["linear_comment_id"] == "1572d3ac-fca9-4713-84e3-4a104c6674fd"
      assert event.external_ids["linear_team_id"] == "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"
      assert event.external_ids["linear_app_user_id"] == "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"

      assert event.external_ids["linear_issue_url"] ==
               "https://linear.app/swarmai/issue/SW-10/improve-readme"

      assert event.external_ids["linear_issue_identifier"] == "SW-10"

      refute Map.has_key?(event.external_ids, "linear_document_id")

      # Verify context extraction
      assert event.context.action == "issueCommentMention"
      assert event.context.notification["type"] == "issueCommentMention"

      assert event.context.notification["comment"]["body"] ==
               "This is a mention comment @swarm-ai-dev "

      assert event.context.notification["comment"]["id"] == "1572d3ac-fca9-4713-84e3-4a104c6674fd"
      assert event.context.notification["issue"]["identifier"] == "SW-10"
    end

    test "creates event from linear issue new comment of app parent comment" do
      event_data = LinearEventsFixtures.linear_issue_new_child_comment_of_app_parent_params()

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.source == :linear
      assert event.type == "issueNewComment"
      assert event.raw_data == event_data

      # Verify external IDs extraction
      assert event.external_ids["linear_issue_id"] == "19e7fc32-f536-4bbc-8f44-e679c6b95580"
      assert event.external_ids["linear_comment_id"] == "82736cf1-a67c-48d7-b532-234c556831f9"
      assert event.external_ids["linear_team_id"] == "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"
      assert event.external_ids["linear_app_user_id"] == "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"

      assert event.external_ids["linear_parent_comment_id"] ==
               "a75617f5-250a-4778-9e18-e271458e32a0"

      assert event.external_ids["linear_parent_comment_user_id"] ==
               "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
    end

    test "creates event from linear document mention" do
      event_data = LinearEventsFixtures.linear_document_mention_params()

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.source == :linear
      assert event.type == "documentMention"
      assert event.raw_data == event_data

      # Verify external IDs extraction
      assert event.external_ids["linear_document_id"] == "f433ebff-9cd0-4057-867a-2ab6e528a12d"
      assert event.external_ids["linear_project_id"] == "bd51cbd8-589f-4122-8326-4347fb0c89ce"
      assert event.external_ids["linear_app_user_id"] == "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
      refute Map.has_key?(event.external_ids, "linear_issue_id")
      refute Map.has_key?(event.external_ids, "linear_comment_id")
      refute Map.has_key?(event.external_ids, "linear_team_id")

      # Verify context extraction
      assert event.context.action == "documentMention"
      assert event.context.notification["type"] == "documentMention"
      assert event.context.notification["document"]["title"] == "Test doc"
      assert event.context.notification["document"]["project"]["name"] == "Test project"
    end

    test "creates event from linear issue new comment" do
      event_data = LinearEventsFixtures.linear_issue_new_comment_params()

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.source == :linear
      assert event.type == "issueNewComment"
      assert event.raw_data == event_data

      # Verify external IDs extraction
      assert event.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"
      assert event.external_ids["linear_comment_id"] == "ff7ece6b-be23-4c5d-a13b-76ae72ea43d8"
      assert event.external_ids["linear_team_id"] == "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"
      assert event.external_ids["linear_app_user_id"] == "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"

      # Verify context extraction
      assert event.context.action == "issueNewComment"
      assert event.context.notification["type"] == "issueNewComment"

      assert event.context.notification["comment"]["body"] ==
               "We should look into this at some point"

      assert event.context.notification["issue"]["identifier"] == "SW-10"
    end

    test "creates event with custom user_id and repository_external_id options" do
      event_data = LinearEventsFixtures.linear_issue_description_mention_params()

      opts = [
        user_id: 123,
        repository_external_id: "github:456789",
        context: %{custom: "data"}
      ]

      assert {:ok, event} = Event.new(event_data, :linear, opts)

      assert event.user_id == 123
      assert event.repository_external_id == "github:456789"
      assert event.context.custom == "data"
      # Should still have Linear-specific context
      assert event.context.action == "issueMention"
    end
  end

  describe "new/3 with GitHub events" do
    test "creates event from GitHub issue" do
      event_data = GitHubEventsFixtures.github_issue_opened_event()

      assert {:ok, event} = Event.new(event_data, :github)

      assert event.source == :github
      assert event.type == "issue"
      assert event.repository_external_id == "github:958906859"
      assert event.external_ids["github_issue_id"] == 3_165_166_522
      assert event.external_ids["github_issue_number"] == 7
      assert event.external_ids["github_issue_url"] == "https://github.com/jonator/swarm/issues/7"
      assert event.external_ids["github_sender_login"] == "jonator"
      assert event.external_ids["github_repository_id"] == 958_906_859
      refute Map.has_key?(event.external_ids, "github_pull_request_id")
    end

    test "creates event from GitHub issue opened with mention" do
      event_data = GitHubEventsFixtures.github_issue_opened_mentioned_event()

      assert {:ok, event} = Event.new(event_data, :github)

      assert event.source == :github
      assert event.type == "issue"
      assert event.repository_external_id == "github:958906859"
      assert event.external_ids["github_issue_id"] == 3_165_166_522
      assert event.external_ids["github_issue_number"] == 7
      assert event.external_ids["github_issue_url"] == "https://github.com/jonator/swarm/issues/7"
      assert event.external_ids["github_sender_login"] == "jonator"
      assert event.external_ids["github_repository_id"] == 958_906_859
      refute Map.has_key?(event.external_ids, "github_pull_request_id")

      # Verify context extraction
      assert event.context.action == "opened"
      assert event.context.issue["body"] == "Hey @swarm-ai-dev can you do this"
      assert String.contains?(event.context.issue["body"], "@swarm-ai-dev")
    end

    test "creates event from GitHub issue edited with mention" do
      event_data = GitHubEventsFixtures.github_issue_edited_event()

      assert {:ok, event} = Event.new(event_data, :github)

      assert event.source == :github
      assert event.type == "issue"
      assert event.repository_external_id == "github:958906859"
      assert event.external_ids["github_issue_id"] == 3_161_734_342
      assert event.external_ids["github_issue_number"] == 5
      assert event.external_ids["github_issue_url"] == "https://github.com/jonator/swarm/issues/5"
      assert event.external_ids["github_sender_login"] == "jonator"
      assert event.external_ids["github_repository_id"] == 958_906_859
      refute Map.has_key?(event.external_ids, "github_pull_request_id")

      # Verify context extraction
      assert event.context.action == "edited"
      assert event.context.issue["body"] == "@swarm-ai-dev test"
      assert String.contains?(event.context.issue["body"], "@swarm-ai-dev")
    end

    test "creates event from GitHub issue comment created" do
      event_data = GitHubEventsFixtures.github_issue_comment_mention_created_event()

      assert {:ok, event} = Event.new(event_data, :github)

      assert event.source == :github
      assert event.type == "issue_comment"
      assert event.repository_external_id == "github:958906859"
      assert event.external_ids["github_comment_id"] == 2_993_623_398
      assert event.external_ids["github_issue_id"] == 3_161_734_342
      assert event.external_ids["github_issue_number"] == 5
      assert event.external_ids["github_issue_url"] == "https://github.com/jonator/swarm/issues/5"
      assert event.external_ids["github_sender_login"] == "jonator"
      assert event.external_ids["github_repository_id"] == 958_906_859
      refute Map.has_key?(event.external_ids, "github_pull_request_id")

      # Verify context extraction
      assert event.context.action == "created"
      assert event.context.comment["body"] == "Test comment 3 @swarm-ai-dev"
      assert event.context.comment["id"] == 2_993_623_398
      assert event.context.issue["id"] == 3_161_734_342
      # Verify mention detection
      assert String.contains?(event.context.comment["body"], "@swarm-ai-dev")
    end

    test "returns error for unknown GitHub event type" do
      event_data = %{
        "unknown_field" => %{"id" => 12345}
      }

      assert {:error, "Unknown GitHub event type"} = Event.new(event_data, :github)
    end
  end

  describe "new/3 with Slack events" do
    test "creates event from Slack app mention" do
      event_data = %{
        "event" => %{
          "type" => "app_mention",
          "ts" => "1234567890.123456",
          "text" => "Hello @bot"
        },
        "team_id" => "T123456"
      }

      assert {:ok, event} = Event.new(event_data, :slack)

      assert event.source == :slack
      assert event.type == "thread_mention"
      assert event.external_ids["slack_thread_id"] == "1234567890.123456"

      # Verify context
      assert event.context.team_id == "T123456"
      assert event.context.event["type"] == "app_mention"
    end

    test "creates event from Slack direct message" do
      event_data = %{
        "event" => %{
          "type" => "message",
          "channel_type" => "im",
          "ts" => "1234567890.123456",
          "text" => "Hello"
        },
        "team_id" => "T123456"
      }

      assert {:ok, event} = Event.new(event_data, :slack)

      assert event.source == :slack
      assert event.type == "direct_message"
      assert event.external_ids["slack_thread_id"] == "1234567890.123456"
    end

    test "returns error for unknown Slack event type" do
      event_data = %{
        "event" => %{
          "type" => "unknown_type",
          "ts" => "1234567890.123456"
        },
        "team_id" => "T123456"
      }

      assert {:error, "Unknown Slack event type"} = Event.new(event_data, :slack)
    end
  end

  describe "new/3 with manual events" do
    test "creates event from manual trigger" do
      event_data = %{"custom" => "data", "user" => "admin"}

      assert {:ok, event} = Event.new(event_data, :manual)

      assert event.source == :manual
      assert event.type == "agent_spawn_request"
      assert event.raw_data == event_data
      assert event.external_ids == %{}
      assert event.context == event_data
    end

    test "creates manual event with custom context" do
      event_data = %{"request" => "spawn_agent"}
      opts = [context: %{"priority" => "high"}]

      assert {:ok, event} = Event.new(event_data, :manual, opts)

      assert event.context["priority"] == "high"
      assert event.context["request"] == "spawn_agent"
    end
  end

  describe "new/3 error cases" do
    test "returns error for Linear event without action" do
      event_data = %{"data" => %{"issue" => %{"id" => "123"}}}

      assert {:error, "Missing action field in Linear event"} = Event.new(event_data, :linear)
    end

    test "returns error for Linear event with invalid action" do
      event_data = %{"action" => 123, "data" => %{"issue" => %{"id" => "123"}}}

      assert {:error, "Invalid action field in Linear event"} = Event.new(event_data, :linear)
    end
  end

  describe "timestamp handling" do
    test "sets timestamp to current time" do
      event_data = LinearEventsFixtures.linear_issue_description_mention_params()
      before_time = DateTime.utc_now()

      assert {:ok, event} = Event.new(event_data, :linear)

      after_time = DateTime.utc_now()
      assert DateTime.compare(event.timestamp, before_time) in [:gt, :eq]
      assert DateTime.compare(event.timestamp, after_time) in [:lt, :eq]
    end
  end

  describe "external IDs extraction edge cases" do
    test "handles Linear event with missing notification data" do
      event_data = %{
        "action" => "custom",
        "data" => %{"issue" => %{"id" => "issue-123"}},
        "appUserId" => "user-456"
      }

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.external_ids["linear_issue_id"] == "issue-123"
      assert event.external_ids["linear_app_user_id"] == "user-456"
      refute Map.has_key?(event.external_ids, "linear_team_id")
    end

    test "handles Linear event with direct issue format" do
      event_data = %{
        "action" => "test",
        "data" => %{"id" => "direct-issue-123"},
        "type" => "Issue"
      }

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.external_ids["linear_issue_id"] == "direct-issue-123"
    end

    test "handles Linear event with legacy comment format" do
      event_data = %{
        "action" => "commentCreated",
        "data" => %{"comment" => %{"id" => "legacy-comment-123"}},
        "appUserId" => "user-789"
      }

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.external_ids["linear_comment_id"] == "legacy-comment-123"
      assert event.external_ids["linear_app_user_id"] == "user-789"
    end

    test "handles Linear event with alternative document ID format" do
      event_data = %{
        "action" => "documentUpdated",
        "notification" => %{"documentId" => "alt-doc-456"},
        "appUserId" => "user-abc"
      }

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.external_ids["linear_document_id"] == "alt-doc-456"
      assert event.external_ids["linear_app_user_id"] == "user-abc"
    end

    test "handles Linear event with team ID from issue" do
      event_data = %{
        "action" => "issueCreated",
        "notification" => %{
          "issue" => %{"teamId" => "team-from-issue-789"}
        }
      }

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.external_ids["linear_team_id"] == "team-from-issue-789"
    end

    test "handles Slack event without timestamp" do
      event_data = %{
        "event" => %{
          "type" => "app_mention",
          "text" => "Hello @bot"
        },
        "team_id" => "T123456"
      }

      assert {:ok, event} = Event.new(event_data, :slack)

      assert event.source == :slack
      assert event.type == "thread_mention"
      refute Map.has_key?(event.external_ids, "slack_thread_id")
    end
  end

  describe "context merging" do
    test "merges base context with source-specific context for Linear events" do
      event_data = LinearEventsFixtures.linear_issue_description_mention_params()
      opts = [context: %{"priority" => "high", "source" => "webhook"}]

      assert {:ok, event} = Event.new(event_data, :linear, opts)

      # Should have both base and Linear-specific context
      assert event.context["priority"] == "high"
      assert event.context["source"] == "webhook"
      assert event.context.action == "issueMention"
      assert event.context.organization_id == "4fde7f37-de48-4d5c-93fb-473c8f24d4cb"
    end

    test "source context takes precedence over base context for overlapping keys" do
      event_data = %{
        "action" => "test",
        "actor" => %{"id" => "linear-actor"}
      }

      opts = [context: %{"action" => "base-action", "actor" => %{"id" => "base-actor"}}]

      assert {:ok, event} = Event.new(event_data, :linear, opts)

      # Linear context should override base context
      assert event.context.action == "test"
      assert event.context.actor["id"] == "linear-actor"
    end
  end

  describe "data validation" do
    test "handles Linear events with minimal required data" do
      event_data = %{"action" => "minimal"}

      assert {:ok, event} = Event.new(event_data, :linear)

      assert event.source == :linear
      assert event.type == "minimal"
      assert event.external_ids == %{}
      assert event.context.action == "minimal"
    end

    test "validates timestamp is recent" do
      event_data = LinearEventsFixtures.linear_issue_description_mention_params()
      before_time = DateTime.utc_now()

      assert {:ok, event} = Event.new(event_data, :linear)

      time_diff = DateTime.diff(event.timestamp, before_time, :millisecond)
      assert time_diff >= 0
      # Should be created within 1 second
      assert time_diff < 1000
    end
  end
end
