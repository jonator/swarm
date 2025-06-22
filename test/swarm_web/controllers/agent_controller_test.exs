defmodule SwarmWeb.AgentControllerTest do
  use SwarmWeb.ConnCase

  import Swarm.AccountsFixtures
  import Swarm.AgentsFixtures
  import Swarm.OrganizationsFixtures
  import Swarm.RepositoriesFixtures

  setup %{conn: conn} do
    # Create a regular user for authentication
    user = user_fixture(%{email: "user@test.com", username: "testuser"})

    # Create a personal organization for the user
    organization = personal_organization_fixture(user)

    # Create a repository for the user
    repository =
      repository_fixture(user, %{
        owner: user.username,
        external_id: "github:654321",
        organization_id: organization.id
      })

    # Generate a JWT token for the user
    {:ok, token, _} =
      SwarmWeb.Auth.Guardian.encode_and_sign(user, %{})

    # Add the token to the conn for authenticated requests
    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user, repository: repository}
  end

  describe "index" do
    test "lists all agents for the authenticated user", %{
      conn: conn,
      user: user,
      repository: repository
    } do
      agent = agent_fixture(%{user: user, repository_id: repository.id})
      conn = get(conn, ~p"/api/agents")

      assert [returned_agent] = json_response(conn, 200)["agents"]
      assert returned_agent["id"] == agent.id
      assert returned_agent["name"] == agent.name
      assert returned_agent["context"] == agent.context
      assert returned_agent["status"] == "pending"
      assert returned_agent["source"] == "manual"
      assert returned_agent["type"] == "researcher"
      assert returned_agent["user_id"] == user.id
      assert returned_agent["repository_id"] == repository.id
    end
  end
end
