defmodule SwarmWeb.RepositoryControllerTest do
  use SwarmWeb.ConnCase

  import Swarm.RepositoriesFixtures
  import Swarm.AccountsFixtures
  import Swarm.OrganizationsFixtures
  import Mock

  @create_attrs %{
    external_id: "github:123456",
    name: "test-repo",
    owner: "testuser"
  }
  @invalid_attrs %{
    external_id: nil,
    name: nil,
    owner: nil
  }

  setup %{conn: conn} do
    # Create a regular user for authentication
    user = user_fixture(%{email: "user@test.com", username: "testuser"})

    # Create a personal organization for the user
    _organization = personal_organization_fixture(user)

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
      repository = repository_fixture(user, %{owner: user.username, external_id: "github:654321"})
      conn = get(conn, ~p"/api/users/repositories")

      assert [returned_repo] = json_response(conn, 200)["repositories"]
      assert returned_repo["id"] == repository.id
      assert returned_repo["external_id"] == repository.external_id
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

      assert created_repo["external_id"] == "github:123456"
      assert created_repo["name"] == "test-repo"
      assert created_repo["owner"] == "testuser"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/users/repositories", %{repository: @invalid_attrs})
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "create repository from GitHub" do
    test "creates repository from GitHub repo ID", %{conn: conn, user: user} do
      with_mock Swarm.Services,
        create_repository_from_github: fn ^user, "789012", [%{"name" => "github-repo"}] ->
          {:ok, repository_fixture(user, %{owner: user.username, external_id: "github:789012"})}
        end do
        conn =
          post(conn, ~p"/api/users/repositories", %{
            github_repo_id: "789012",
            projects: [%{name: "github-repo"}]
          })

        assert %{"id" => id} = json_response(conn, 201)["repository"]

        # Verify the repository was created
        conn = get(conn, ~p"/api/users/repositories")
        repositories = json_response(conn, 200)["repositories"]
        created_repo = Enum.find(repositories, fn repo -> repo["id"] == id end)

        assert created_repo["external_id"] == "github:789012"
        assert created_repo["owner"] == user.username
      end
    end

    test "renders errors when neither repository nor github_repo_id is provided", %{conn: conn} do
      conn = post(conn, ~p"/api/users/repositories", %{})

      assert %{"errors" => %{"params" => ["repository or github_repo_id is required"]}} =
               json_response(conn, 422)
    end
  end
end
