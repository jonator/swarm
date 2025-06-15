defmodule Swarm.ServicesTest do
  use Swarm.DataCase

  alias Swarm.Services

  describe "fetch_github_repository/2" do
    test "returns error when repository not found" do
      user = Swarm.AccountsFixtures.user_fixture(%{username: "testuser"})

      # This will fail since we don't have real GitHub tokens in test
      assert {:unauthorized, reason} = Services.fetch_github_repository(user, "99999")
      assert is_binary(reason)
    end
  end

  describe "create_repository_from_github/3" do
    test "returns error when GitHub API is not accessible" do
      user = Swarm.AccountsFixtures.user_fixture(%{username: "testuser"})

      # Without real GitHub integration, this should return an error
      assert {:unauthorized, reason} =
               Services.create_repository_from_github(user, "12345", %{
                 name: "my-repo",
                 type: "nextjs"
               })

      assert is_binary(reason)
    end
  end
end
