defmodule Swarm.Ingress.LinearHandlerTest do
  use Swarm.DataCase
  import Mock

  alias Swarm.Ingress.LinearHandler
  alias Swarm.Ingress.Event
  import Swarm.AccountsFixtures
  import Swarm.RepositoriesFixtures
  import Swarm.EventsFixtures

  @comprehensive_thread %{
    "issue" => %{
      "id" => "71ee683d-74e4-4668-95f7-537af7734054",
      "comments" => %{
        "nodes" => [
          %{
            "id" => "33250e31-de7a-4e93-9bab-7800ee1a4028",
            "body" => "I think we should prioritize the documentation improvements first",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "f1153b76-35c8-4a4b-9f0c-1550f2f3ef06",
            "body" => "Let's make sure to include examples in the README",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{
              "nodes" => [
                %{
                  "id" => "a1b2c3d4-5e6f-7890-abcd-ef1234567890",
                  "body" => "Yes, especially API usage examples would be helpful",
                  "user" => %{"displayName" => "jonathanator0"}
                },
                %{
                  "id" => "b2c3d4e5-6f78-9012-bcde-f23456789012",
                  "body" => "We should also include error handling examples",
                  "user" => %{"displayName" => "jonathanator0"}
                }
              ]
            }
          },
          %{
            "id" => "e3ea6148-7edc-4141-a653-b9e9a9258a8a",
            "body" => "The current README is quite outdated and needs a complete rewrite",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "ff7ece6b-be23-4c5d-a13b-76ae72ea43d8",
            "body" => "We should also consider adding installation instructions",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{
              "nodes" => [
                %{
                  "id" => "c3d4e5f6-7890-1234-cdef-567890123456",
                  "body" =>
                    "Good point! Both npm and yarn installation methods should be covered",
                  "user" => %{"displayName" => "jonathanator0"}
                }
              ]
            }
          },
          %{
            "id" => "1a9e064e-9984-4245-b9f0-ed7cd2005386",
            "body" => "What about adding a getting started guide?",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{
              "nodes" => [
                %{
                  "id" => "b1e49d62-9c8d-41b2-a54d-dbc73291e6e7",
                  "body" => "Great idea! That would really help new contributors",
                  "user" => %{"displayName" => "jonathanator0"}
                },
                %{
                  "id" => "44c60647-2e5a-415c-a789-b36ea89e50c6",
                  "body" => "I can help with writing the getting started section",
                  "user" => %{"displayName" => "jonathanator0"}
                }
              ]
            }
          },
          %{
            "id" => "78e07a97-439f-4e41-ad56-5a9c4970c1ed",
            "body" => "The README should also include contribution guidelines",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "1572d3ac-fca9-4713-84e3-4a104c6674fd",
            "body" => "@swarmdev please make sure to include code examples in the documentation",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{"nodes" => []}
          }
        ]
      }
    }
  }

  @focused_thread %{
    "issue" => %{
      "id" => "71ee683d-74e4-4668-95f7-537af7734054",
      "comments" => %{
        "nodes" => [
          %{
            "id" => "33250e31-de7a-4e93-9bab-7800ee1a4028",
            "body" => "Should we include setup instructions in the README?",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "f1153b76-35c8-4a4b-9f0c-1550f2f3ef06",
            "body" => "The current documentation lacks code examples",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{
              "nodes" => [
                %{
                  "id" => "d4e5f6g7-8901-2345-defg-678901234567",
                  "body" =>
                    "Agreed, we need practical examples that developers can copy and paste",
                  "user" => %{"displayName" => "jonathanator0"}
                },
                %{
                  "id" => "e5f6g7h8-9012-3456-efgh-789012345678",
                  "body" => "Maybe we should add a quickstart section too?",
                  "user" => %{"displayName" => "jonathanator0"}
                }
              ]
            }
          },
          %{
            "id" => "1572d3ac-fca9-4713-84e3-4a104c6674fd",
            "body" => "@swarmdev let's make this README comprehensive and user-friendly",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{"nodes" => []}
          }
        ]
      }
    }
  }

  @comment_mention_thread %{
    "issue" => %{
      "id" => "71ee683d-74e4-4668-95f7-537af7734054",
      "comments" => %{
        "nodes" => [
          %{
            "id" => "33250e31-de7a-4e93-9bab-7800ee1a4028",
            "body" => "Should we include setup instructions in the README?",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "1572d3ac-fca9-4713-84e3-4a104c6674fd",
            "body" => "This is a mention comment @swarmdev",
            "user" => %{"displayName" => "jonathanator0"},
            "children" => %{"nodes" => []}
          }
        ]
      }
    }
  }

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
          email: "jonathanator0@gmail.com",
          username: "jonator"
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

    test "handles Linear issue assigned to swarm event" do
      params = linear_issue_assigned_to_swarm_params()
      {:ok, event} = Event.new(params, :linear)

      with_mock Swarm.Services.Linear,
        issue: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, %{"issue" => %{"documentContent" => %{"content" => "Test issue content"}}}}
        end,
        issue_comment_threads: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, @comprehensive_thread}
        end do
        assert {:ok, attrs} = LinearHandler.handle(event)
        assert attrs.source == :linear
        assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
        assert String.contains?(attrs.context, "Test issue content")

        assert String.contains?(
                 attrs.context,
                 "Linear Issue assigned (71ee683d-74e4-4668-95f7-537af7734054): Improve README"
               )
      end
    end

    test "handles Linear issue description mention event" do
      params = linear_issue_description_mention_params()
      {:ok, event} = Event.new(params, :linear)

      with_mock Swarm.Services.Linear,
        issue_comment_threads: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, @focused_thread}
        end do
        assert {:ok, attrs} = LinearHandler.handle(event)
        assert attrs.source == :linear
        assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"

        assert String.contains?(
                 attrs.context,
                 "Linear Issue mentioned in description (71ee683d-74e4-4668-95f7-537af7734054): Improve README"
               )
      end
    end

    test "handles Linear comment mention event" do
      params = linear_issue_comment_mention_params()
      {:ok, event} = Event.new(params, :linear)

      with_mock Swarm.Services.Linear,
        issue: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, %{"issue" => %{"documentContent" => %{"content" => "Test issue content"}}}}
        end,
        issue_comment_threads: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, @comment_mention_thread}
        end do
        assert {:ok, attrs} = LinearHandler.handle(event)
        assert attrs.source == :linear
        assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"

        assert String.contains?(
                 attrs.context,
                 "Linear Issue mentioned in comment 1572d3ac-fca9-4713-84e3-4a104c6674fd (71ee683d-74e4-4668-95f7-537af7734054): Improve README"
               )

        assert String.contains?(attrs.context, "This is a mention comment @swarmdev")
      end
    end

    test "handles Linear issue new comment event" do
      params = linear_issue_new_comment_params()
      {:ok, event} = Event.new(params, :linear)

      assert {:ok, :ignored} = LinearHandler.handle(event)
    end

    test "handles Linear document mention event", %{user: user, repository: repository} do
      params = linear_document_mention_params()
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
        end,
        issue_comment_threads: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, @focused_thread}
        end do
        assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

        assert attrs.user_id == user.id
        assert attrs.source == :linear
        assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
        assert attrs.repository.id == repository.id

        assert String.contains?(
                 attrs.context,
                 "Linear Issue assigned (71ee683d-74e4-4668-95f7-537af7734054): Improve README"
               )

        assert String.contains?(attrs.context, "Test issue content")
      end
    end

    test "builds correct attributes for comment mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_issue_comment_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      with_mock Swarm.Services.Linear,
        issue: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, %{"issue" => %{"documentContent" => %{"content" => "Test issue content"}}}}
        end,
        issue_comment_threads: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, @comment_mention_thread}
        end do
        assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

        assert attrs.user_id == user.id
        assert attrs.source == :linear
        assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
        assert attrs.repository.id == repository.id

        assert String.contains?(attrs.context, "This is a mention comment @swarmdev")
      end
    end

    test "builds correct attributes for description mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_issue_description_mention_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      with_mock Swarm.Services.Linear,
        issue_comment_threads: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, @focused_thread}
        end do
        assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

        assert attrs.user_id == user.id
        assert attrs.source == :linear
        assert attrs.linear_issue_id == "71ee683d-74e4-4668-95f7-537af7734054"
        assert attrs.repository.id == repository.id

        assert String.contains?(attrs.context, "@swarmdev")
      end
    end

    test "builds correct attributes for document mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_document_mention_params()
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
