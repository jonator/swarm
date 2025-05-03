defmodule SwarmWeb.UserControllerTest do
  use SwarmWeb.ConnCase

  import Swarm.AccountsFixtures

  alias Swarm.Accounts.User

  @create_attrs %{
    email: "test@email.com"
  }
  @update_attrs %{
    email: "updated@email.com"
  }
  @invalid_attrs %{
    email: "invalid_email"
  }

  setup %{conn: conn} do
    # Create an admin user for authentication
    admin = user_fixture(%{email: "admin@test.com", role: "admin"})

    # Generate a JWT token for the admin user
    {:ok, token, _} =
      SwarmWeb.Auth.Guardian.encode_and_sign(admin, %{}, permissions: %{default: [:admin]})

    # Add the token to the conn for authenticated requests
    # Specify the accept header to ensure the response is JSON
    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, ~p"/api/admin/users")

      assert length(json_response(conn, 200)["data"]) == 1
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/admin/users", %{user: @create_attrs})
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/admin/users/#{id}")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/admin/users", %{user: @invalid_attrs})
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id}} do
      conn = put(conn, ~p"/api/admin/users/#{id}", %{user: @update_attrs})
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/admin/users/#{id}")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: %User{id: id}} do
      conn = put(conn, ~p"/api/admin/users/#{id}", %{user: @invalid_attrs})
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: %User{id: id}} do
      conn = delete(conn, ~p"/api/admin/users/#{id}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/admin/users/#{id}")
      end
    end
  end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end
end
