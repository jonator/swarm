defmodule SwarmWeb.RepositoryControllerTest do
  use SwarmWeb.ConnCase

  import Swarm.RepositoriesFixtures
  import Swarm.AccountsFixtures

  @create_attrs %{
    name: "test-repo",
    owner: "testuser"
  }
  @invalid_attrs %{
    name: nil,
    owner: nil
  }

  setup %{conn: conn} do
    # Create a regular user for authentication
    user = user_fixture(%{email: "user@test.com", username: "testuser"})

    # Generate a JWT token for the user
    {:ok, token, _} =
      SwarmWeb.Auth.Guardian.encode_and_sign(user, %{})

    # Add the token to the conn for authenticated requests
    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all repositories for the authenticated user", %{conn: conn, user: user} do
      repository = repository_fixture(user, %{owner: user.username})
      conn = get(conn, ~p"/api/users/repositories")

      assert [returned_repo] = json_response(conn, 200)["repositories"]
      assert returned_repo["id"] == repository.id
      assert returned_repo["name"] == repository.name
      assert returned_repo["owner"] == repository.owner
    end
  end

  describe "create repository" do
    test "renders repository when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/users/repositories", %{repository: @create_attrs})
      assert %{"id" => id} = json_response(conn, 201)["repository"]

      # Check the repository exists by fetching the index
      conn = get(conn, ~p"/api/users/repositories")
      repositories = json_response(conn, 200)["repositories"]
      created_repo = Enum.find(repositories, fn repo -> repo["id"] == id end)

      assert created_repo["name"] == "test-repo"
      assert created_repo["owner"] == "testuser"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/users/repositories", %{repository: @invalid_attrs})
      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end
