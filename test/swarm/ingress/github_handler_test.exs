defmodule Swarm.Ingress.GitHubHandlerTest do
  use Swarm.DataCase, async: true
  import Mock

  alias Swarm.Ingress.GitHubHandler
  alias Swarm.Ingress.Event
  alias Swarm.Services.GitHub
  import Swarm.AccountsFixtures
  import Swarm.RepositoriesFixtures
  import Swarm.GitHubEventsFixtures

  @github_issue_comments [
    %{
      "body" => "This is a comment without a mention.",
      "user" => %{"login" => "another_user"}
    },
    %{
      "body" => "Hey @swarm-ai-dev, can you look at this?",
      "user" => %{"login" => "jonator"}
    },
    %{
      "body" => "I think we should also consider refactoring the parser.",
      "user" => %{"login" => "dev_one"}
    }
  ]

  describe "handle/1" do
    setup do
      user = user_fixture(%{username: "jonator", email: "jonator@test.com"})

      {:ok, _token} =
        Swarm.Accounts.save_token(user, %{
          type: :access,
          context: :github,
          token: "test-token",
          expires_in: 3600
        })

      organization =
        Swarm.Repo.insert!(%Swarm.Organizations.Organization{
          name: "jonator",
          github_installation_id: 67_232_095
        })

      repository =
        repository_fixture(user, %{
          name: "swarm",
          owner: "jonator",
          external_id: "github:958906859",
          organization_id: organization.id
        })

      {:ok, user: user, repository: repository, organization: organization}
    end

    test "ignores github issue opened event without swarm mention", %{user: _user} do
      params = github_issue_opened_event()
      {:ok, event} = Event.new(params, :github)

      assert {:ok, :ignored} == GitHubHandler.handle(event)
    end

    test "handles github issue edited event with swarm mention", %{
      user: user,
      repository: repository,
      organization: _organization
    } do
      params = github_issue_edited_event()
      {:ok, event} = Event.new(params, :github)

      with_mock GitHub,
        new: fn organization ->
          assert organization.name == "jonator"
          {:ok, %GitHub{client: Tentacat.Client.new()}}
        end,
        issue_comments: fn _client, "jonator", "swarm", 5 ->
          {:ok, @github_issue_comments}
        end do
        assert {:ok, attrs} = GitHubHandler.handle(event)

        assert attrs.user_id == user.id
        assert attrs.repository.id == repository.id
        assert attrs.source == :github
        assert attrs.external_ids["github_issue_id"] == 3_161_734_342

        assert String.contains?(attrs.context, "GitHub Issue edited: Test5")
        assert String.contains?(attrs.context, "Description:\n@swarm-ai-dev test")
        assert String.contains?(attrs.context, "Comments:")

        assert String.contains?(
                 attrs.context,
                 "- @another_user: This is a comment without a mention."
               )

        assert String.contains?(
                 attrs.context,
                 "- @jonator: Hey @swarm-ai-dev, can you look at this?"
               )

        assert String.contains?(
                 attrs.context,
                 "- @dev_one: I think we should also consider refactoring the parser."
               )

        assert String.contains?(
                 attrs.context,
                 "Issue URL: https://github.com/jonator/swarm/issues/5"
               )
      end
    end

    test "handles github issue opened event with swarm mention", %{
      user: user,
      repository: repository,
      organization: _organization
    } do
      params = github_issue_opened_mentioned_event()
      {:ok, event} = Event.new(params, :github)

      with_mock GitHub,
        new: fn organization ->
          assert organization.name == "jonator"
          {:ok, %GitHub{client: Tentacat.Client.new()}}
        end,
        issue_comments: fn _client, "jonator", "swarm", 7 ->
          {:ok, @github_issue_comments}
        end do
        assert {:ok, attrs} = GitHubHandler.handle(event)

        assert attrs.user_id == user.id
        assert attrs.repository.id == repository.id
        assert attrs.source == :github
        assert attrs.external_ids["github_issue_id"] == 3_165_166_522

        assert String.contains?(attrs.context, "GitHub Issue opened: Swarm's Issue")

        assert String.contains?(
                 attrs.context,
                 "Description:\nHey @swarm-ai-dev can you do this"
               )

        assert String.contains?(attrs.context, "Comments:")

        assert String.contains?(
                 attrs.context,
                 "- @another_user: This is a comment without a mention."
               )

        assert String.contains?(
                 attrs.context,
                 "- @jonator: Hey @swarm-ai-dev, can you look at this?"
               )

        assert String.contains?(
                 attrs.context,
                 "- @dev_one: I think we should also consider refactoring the parser."
               )

        assert String.contains?(
                 attrs.context,
                 "Issue URL: https://github.com/jonator/swarm/issues/7"
               )
      end
    end

    test "handles github issue comment created event with swarm mention", %{
      user: user,
      repository: repository,
      organization: _organization
    } do
      params = github_issue_comment_mention_created_event()
      {:ok, event} = Event.new(params, :github)

      with_mock GitHub,
        new: fn organization ->
          assert organization.name == "jonator"
          {:ok, %GitHub{client: Tentacat.Client.new()}}
        end,
        issue_comments: fn _client, "jonator", "swarm", 5 ->
          {:ok, @github_issue_comments}
        end do
        assert {:ok, attrs} = GitHubHandler.handle(event)

        assert attrs.user_id == user.id
        assert attrs.repository.id == repository.id
        assert attrs.source == :github
        assert attrs.external_ids["github_issue_id"] == 3_161_734_342

        assert String.contains?(attrs.context, "GitHub Issue created: Test5")
        assert String.contains?(attrs.context, "Description:\n@swarm-ai-dev test")
        assert String.contains?(attrs.context, "Comments:")

        assert String.contains?(
                 attrs.context,
                 "- @another_user: This is a comment without a mention."
               )

        assert String.contains?(
                 attrs.context,
                 "- @jonator: Hey @swarm-ai-dev, can you look at this?"
               )

        assert String.contains?(
                 attrs.context,
                 "- @dev_one: I think we should also consider refactoring the parser."
               )

        assert String.contains?(
                 attrs.context,
                 "Issue URL: https://github.com/jonator/swarm/issues/5"
               )
      end
    end
  end
end
