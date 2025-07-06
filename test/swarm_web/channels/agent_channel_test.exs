import Swarm.AccountsFixtures
import Swarm.AgentsFixtures
import Swarm.OrganizationsFixtures
import Swarm.RepositoriesFixtures

defmodule SwarmWeb.AgentChannelTest do
  use SwarmWeb.ChannelCase

  setup do
    user = user_fixture(%{email: "user@test.com", username: "testuser"})
    organization = personal_organization_fixture(user)

    repository =
      repository_fixture(user, %{owner: user.username, organization_id: organization.id})

    agent = agent_fixture(%{user: user, repository_id: repository.id})
    {:ok, token, _} = SwarmWeb.Auth.Guardian.encode_and_sign(user, %{})
    topic = "agent:#{agent.id}"
    payload = %{"token" => token}

    {:ok, _, socket} =
      SwarmWeb.UserSocket
      |> socket(nil, %{})
      |> subscribe_and_join(SwarmWeb.AgentChannel, topic, payload)

    %{socket: socket}
  end

  test "user_message broadcasts to agent:<id>", %{socket: socket} do
    push(socket, "user_message", %{"hello" => "all"})
    assert_broadcast "user_message", %{"hello" => "all"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "user_message", %{"some" => "data"})
    assert_push "user_message", %{"some" => "data"}
  end
end
