defmodule Swarm.Ingress.PermissionsTest do
  use Swarm.DataCase
  import Mock

  alias Swarm.Ingress.Permissions
  alias Swarm.Ingress.Event

  import Swarm.AccountsFixtures
  import Swarm.RepositoriesFixtures
  import Swarm.LinearEventsFixtures

  describe "validate_repository_access/2 for Linear events" do
    setup do
      user =
        user_fixture(%{
          email: "test-repo-#{:rand.uniform(10000)}@example.com",
          username: "test-repo-user-#{:rand.uniform(10000)}"
        })

      # Create Linear access token for the user
      {:ok, _token} =
        Swarm.Accounts.save_token(user, %{
          token: "test_linear_token",
          expires_in: 3600,
          context: :linear,
          type: :access,
          linear_workspace_external_id: "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
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

      assert {:ok, found_repo, _org} = Permissions.validate_repository_access(user, event)
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
               Permissions.validate_repository_access(user, event)
    end

    test "returns error when user has no repositories", %{user: user} do
      params = linear_issue_assigned_to_swarm_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      assert {:error, "No repositories found for user"} =
               Permissions.validate_repository_access(user, event)
    end

    test "finds repository by project ID mapping for document mention", %{user: user} do
      repository =
        repository_fixture(user, %{
          name: "Swarm Repo",
          owner: user.username,
          external_id: "github:#{:rand.uniform(10000)}",
          linear_team_external_ids: ["2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"]
        })

      params = linear_document_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      with_mock Swarm.Services.Linear,
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
        assert {:ok, found_repo, _org} = Permissions.validate_repository_access(user, event)
        assert found_repo.id == repository.id
      end
    end
  end
end
