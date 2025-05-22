defmodule SwarmWeb.UserControllerTest do
  use SwarmWeb.ConnCase

  import Swarm.AccountsFixtures

  alias Swarm.Accounts.User

  @create_attrs %{
    email: "create@email.com",
    avatar_url: "https://example.com/avatar.jpg",
    username: "createuser"
  }
  @update_attrs %{
    email: "updated@email.com",
    avatar_url: "https://example.com/updated_avatar.jpg",
    username: "updateduser"
  }
  @invalid_attrs %{
    email: "invalid_email",
    avatar_url: "not_a_url",
    username: nil
  }

  setup %{conn: conn} do
    # Create an admin user for authentication
    admin = user_fixture(%{email: "admin@test.com", username: "adminuser", role: "admin"})

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
      response = json_response(conn, 200)["data"]
      assert %{
        "id" => ^id,
        "avatar_url" => "https://example.com/avatar.jpg",
        "email" => "create@email.com",
        "username" => "createuser",
        "role" => "user",
        "created_at" => _,
        "updated_at" => _
      } = response
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/admin/users", %{user: @invalid_attrs})
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders errors when avatar_url is too long", %{conn: conn} do
      attrs = Map.put(@create_attrs, :avatar_url, "https://" <> String.duplicate("a", 300) <> ".com/image.jpg")
      conn = post(conn, ~p"/api/admin/users", %{user: attrs})
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders errors when avatar_url is not a valid URL", %{conn: conn} do
      attrs = Map.put(@create_attrs, :avatar_url, "not_a_url")
      conn = post(conn, ~p"/api/admin/users", %{user: attrs})
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id}} do
      conn = put(conn, ~p"/api/admin/users/#{id}", %{user: @update_attrs})
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/admin/users/#{id}")
      response = json_response(conn, 200)["data"]
      assert %{
        "id" => ^id,
        "avatar_url" => "https://example.com/updated_avatar.jpg",
        "email" => "updated@email.com",
        "username" => "updateduser",
        "role" => "user",
        "created_at" => _,
        "updated_at" => _
      } = response
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
