defmodule Swarm.Ingress.LinearHandlerTest do
  use Swarm.DataCase
  import Mock

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
        type: :access,
        linear_workspace_external_id: "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
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

      with_mock Swarm.Services.Linear,
        issue: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, %{"issue" => %{"documentContent" => %{"content" => "Test issue content"}}}}
        end do
        assert {:ok, attrs} = LinearHandler.handle(event)
        assert attrs.source == :linear
        assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
        assert String.contains?(attrs.context, "Test issue content")
        assert String.contains?(attrs.context, "Linear Issue assigned: Improve README")
      end
    end

    test "handles Linear issue description mention event", %{user: user} do
      params = linear_issue_description_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, attrs} = LinearHandler.handle(event)
      assert attrs.source == :linear
      assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"

      assert String.contains?(
               attrs.context,
               "Linear Issue mentioned in description: Improve README"
             )
    end

    test "handles Linear comment mention event", %{user: user} do
      params = linear_issue_comment_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, attrs} = LinearHandler.handle(event)
      assert attrs.source == :linear
      assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
      assert String.contains?(attrs.context, "Linear Comment Mention in Issue: Improve README")
      assert String.contains?(attrs.context, "This is a mention comment @swarmdev")
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

    test "handles Linear document mention event", %{user: user, repository: repository} do
      params = linear_document_mention()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      with_mock Swarm.Services.Linear,
        document: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                     "f433ebff-9cd0-4057-867a-2ab6e528a12d" ->
          {:ok,
           %{
             "document" => %{
               "id" => "doc_123",
               "title" => "Test Document",
               "content" => "This is a test document content",
               "url" => "https://linear.app/test/doc_123"
             }
           }}
        end,
        project: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                    "bd51cbd8-589f-4122-8326-4347fb0c89ce" ->
          {:ok,
           %{
             "project" => %{
               "id" => "bd51cbd8-589f-4122-8326-4347fb0c89ce",
               "name" => "Test project",
               "teams" => %{
                 "nodes" => [
                   %{
                     "id" => "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"
                   }
                 ]
               }
             }
           }}
        end do
        assert {:ok, attrs} = LinearHandler.handle(event)

        assert attrs.source == :linear
        assert attrs.linear_document_id == "f433ebff-9cd0-4057-867a-2ab6e528a12d"
        assert attrs.repository.id == repository.id
        assert String.contains?(attrs.context, "Test doc")
        assert String.contains?(attrs.context, "This is a test document content")
      end
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

      # Create Linear access token for document fetching
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

    test "builds correct attributes for issue assigned event", %{
      user: user,
      repository: repository
    } do
      params = linear_issue_assigned_to_swarm_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      with_mock Swarm.Services.Linear,
        issue: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, %{"issue" => %{"documentContent" => %{"content" => "Test issue content"}}}}
        end do
        assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

        assert attrs.user_id == user.id
        assert attrs.source == :linear
        assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
        assert attrs.repository.id == repository.id

        assert String.contains?(attrs.context, "Linear Issue assigned: Improve README")
        assert String.contains?(attrs.context, "Test issue content")
      end
    end

    test "builds correct attributes for comment mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_issue_comment_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

      assert attrs.user_id == user.id
      assert attrs.source == :linear
      assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
      assert attrs.repository.id == repository.id

      assert String.contains?(attrs.context, "This is a mention comment @swarmdev")
    end

    test "builds correct attributes for description mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_issue_description_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

      assert attrs.user_id == user.id
      assert attrs.source == :linear
      assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
      assert attrs.repository.id == repository.id

      assert String.contains?(attrs.context, "@swarmdev")
    end

    test "builds correct attributes for document mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_document_mention()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      with_mock Swarm.Services.Linear,
        document: fn _linear, _document_id ->
          {:ok,
           %{
             "document" => %{
               "id" => "doc_123",
               "title" => "Test Document",
               "content" => "This is a test document content",
               "url" => "https://linear.app/test/doc_123"
             }
           }}
        end do
        assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

        assert attrs.user_id == user.id
        assert attrs.source == :linear
        assert attrs.linear_document_id == "f433ebff-9cd0-4057-867a-2ab6e528a12d"
        assert attrs.repository.id == repository.id
        assert String.contains?(attrs.context, "Test doc")
        assert String.contains?(attrs.context, "This is a test document content")
      end
    end
  end
end
