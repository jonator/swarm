defmodule Swarm.Ingress.LinearHandlerTest do
  use Swarm.DataCase
  import Mock

  alias Swarm.Ingress.LinearHandler
  alias Swarm.Ingress.Event
  import Swarm.AccountsFixtures
  import Swarm.RepositoriesFixtures
  import Swarm.LinearEventsFixtures

  @comprehensive_thread %{
    "issue" => %{
      "id" => "71ee683d-74e4-4668-95f7-537af7734054",
      "comments" => %{
        "nodes" => [
          %{
            "id" => "5baced2d-7373-4861-ab9b-4dcc50f751e5",
            "body" => "TESTREPLY! [link](https://www.google.com/maps)",
            "user" => %{"displayName" => "swarmdev"},
            "createdAt" => "2025-06-16T00:37:35.618Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "1194b8de-a41c-4000-a6fc-a4b85d930e84",
            "body" => "@swarmdev test",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-11T00:41:37.712Z",
            "children" => %{
              "nodes" => [
                %{
                  "id" => "359cf172-a0e5-4fd3-9659-be6002d1b6d9",
                  "body" => "TESTREPLY! [link](https://www.google.com/maps)",
                  "user" => %{"displayName" => "swarmdev"},
                  "createdAt" => "2025-06-16T00:36:44.240Z"
                },
                %{
                  "id" => "1bdd962a-7ba1-4afe-b7cc-11ba780f21ce",
                  "body" => "TESTREPLY!",
                  "user" => %{"displayName" => "swarmdev"},
                  "createdAt" => "2025-06-16T00:34:12.590Z"
                }
              ]
            }
          },
          %{
            "id" => "90a8be01-adbb-458e-8af2-404c3aea1afd",
            "body" => "test",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-11T00:41:22.526Z",
            "children" => %{
              "nodes" => [
                %{
                  "id" => "d89bbe9a-851e-41e5-a3bf-53bcf6b7e182",
                  "body" => "testreply",
                  "user" => %{"displayName" => "jonathanator0"},
                  "createdAt" => "2025-06-16T00:57:41.660Z"
                }
              ]
            }
          },
          %{
            "id" => "33250e31-de7a-4e93-9bab-7800ee1a4028",
            "body" => "TEST6",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T15:03:30.419Z",
            "children" => %{
              "nodes" => [
                %{
                  "id" => "66bd6984-9908-4adf-9f7b-64b1cb23c88b",
                  "body" => "@swarmdev reply",
                  "user" => %{"displayName" => "jonathanator0"},
                  "createdAt" => "2025-06-16T01:05:17.164Z"
                },
                %{
                  "id" => "35936467-4d3c-4ef5-91da-5089ccc0c2ac",
                  "body" => "test6reply",
                  "user" => %{"displayName" => "jonathanator0"},
                  "createdAt" => "2025-06-16T00:58:03.915Z"
                }
              ]
            }
          },
          %{
            "id" => "f1153b76-35c8-4a4b-9f0c-1550f2f3ef06",
            "body" => "TEST5",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T15:01:23.480Z",
            "children" => %{
              "nodes" => [
                %{
                  "id" => "fcad6306-a8a1-4271-9056-66d74ee6d88e",
                  "body" => "test5reply",
                  "user" => %{"displayName" => "jonathanator0"},
                  "createdAt" => "2025-06-16T00:58:21.459Z"
                }
              ]
            }
          },
          %{
            "id" => "e3ea6148-7edc-4141-a653-b9e9a9258a8a",
            "body" => "TEST4",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:59:49.453Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "ff7ece6b-be23-4c5d-a13b-76ae72ea43d8",
            "body" => "We should look into this at some point",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:44:02.646Z",
            "children" => %{
              "nodes" => [
                %{
                  "id" => "a8dce0cb-5ac1-4f94-9cb2-8696f809498e",
                  "body" => "Yes",
                  "user" => %{"displayName" => "jonathanator0"},
                  "createdAt" => "2025-06-16T00:51:22.220Z"
                }
              ]
            }
          },
          %{
            "id" => "7977bd09-081c-4abe-b629-5f6b0856d829",
            "body" => "TEST3",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:36:32.520Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "1a9e064e-9984-4245-b9f0-ed7cd2005386",
            "body" => "TEST2",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:36:13.133Z",
            "children" => %{
              "nodes" => [
                %{
                  "id" => "b1e49d62-9c8d-41b2-a54d-dbc73291e6e7",
                  "body" => "TEST2 Reply2",
                  "user" => %{"displayName" => "jonathanator0"},
                  "createdAt" => "2025-06-07T15:24:51.876Z"
                },
                %{
                  "id" => "44c60647-2e5a-415c-a789-b36ea89e50c6",
                  "body" => "TEST2 Reply",
                  "user" => %{"displayName" => "jonathanator0"},
                  "createdAt" => "2025-06-07T15:21:38.423Z"
                }
              ]
            }
          },
          %{
            "id" => "78e07a97-439f-4e41-ad56-5a9c4970c1ed",
            "body" => "TEST",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:35:34.362Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "e1201649-4706-4fea-83bb-9618fe6e3ec3",
            "body" => "OK",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:18:00.364Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "d19aa129-2b2d-41ad-a977-9d7d2147808d",
            "body" => "What should we do here?",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:17:37.296Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "b1ef5755-7d7c-45a4-91cb-835e90d8d4eb",
            "body" => "@jon thank you",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:17:00.364Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "0b4771ef-1812-4d3c-a565-4255ecc28b13",
            "body" => "Another comment",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:16:00.364Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "1572d3ac-fca9-4713-84e3-4a104c6674fd",
            "body" => "This is a mention comment @swarmdev ",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:15:00.364Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "106941ea-0453-4ebe-9215-5ef982fd80ea",
            "body" => "This is a comment",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:14:00.364Z",
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
            "createdAt" => "2025-06-07T14:17:37.296Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "f1153b76-35c8-4a4b-9f0c-1550f2f3ef06",
            "body" => "The current documentation lacks code examples",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:18:00.364Z",
            "children" => %{
              "nodes" => [
                %{
                  "id" => "d4e5f6g7-8901-2345-defg-678901234567",
                  "body" =>
                    "Agreed, we need practical examples that developers can copy and paste",
                  "user" => %{"displayName" => "jonathanator0"},
                  "createdAt" => "2025-06-07T14:18:30.364Z"
                },
                %{
                  "id" => "e5f6g7h8-9012-3456-efgh-789012345678",
                  "body" => "Maybe we should add a quickstart section too?",
                  "user" => %{"displayName" => "jonathanator0"},
                  "createdAt" => "2025-06-07T14:19:00.364Z"
                }
              ]
            }
          },
          %{
            "id" => "1572d3ac-fca9-4713-84e3-4a104c6674fd",
            "body" => "@swarmdev let's make this README comprehensive and user-friendly",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:20:00.364Z",
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
            "createdAt" => "2025-06-07T14:17:37.296Z",
            "children" => %{"nodes" => []}
          },
          %{
            "id" => "1572d3ac-fca9-4713-84e3-4a104c6674fd",
            "body" => "This is a mention comment @swarmdev",
            "user" => %{"displayName" => "jonathanator0"},
            "createdAt" => "2025-06-07T14:20:00.364Z",
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
        assert attrs.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"
        assert String.contains?(attrs.context, "Test issue content")

        assert String.contains?(
                 attrs.context,
                 "Linear Issue assigned (Issue ID: 71ee683d-74e4-4668-95f7-537af7734054): Improve README"
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
        assert attrs.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"

        assert String.contains?(
                 attrs.context,
                 "Linear Issue mentioned in description (Issue ID: 71ee683d-74e4-4668-95f7-537af7734054): Improve README"
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
        assert attrs.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"

        assert String.contains?(
                 attrs.context,
                 "Linear Issue mentioned in comment 1572d3ac-fca9-4713-84e3-4a104c6674fd (Issue ID: 71ee683d-74e4-4668-95f7-537af7734054): Improve README"
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
        assert attrs.external_ids["linear_document_id"] == "f433ebff-9cd0-4057-867a-2ab6e528a12d"
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
        assert attrs.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"
        assert attrs.repository.id == repository.id

        assert String.contains?(
                 attrs.context,
                 "Linear Issue assigned (Issue ID: 71ee683d-74e4-4668-95f7-537af7734054): Improve README"
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
        assert attrs.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"
        assert attrs.repository.id == repository.id

        assert String.contains?(attrs.context, "This is a mention comment @swarmdev")
      end
    end

    test "builds correct attributes for child comment mention event", %{
      user: user,
      repository: repository
    } do
      params = linear_issue_new_child_comment_params()
      {:ok, event} = Event.new(params, :linear, user_id: user.id)

      with_mock Swarm.Services.Linear,
        issue: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, %{"issue" => %{"documentContent" => %{"content" => "Test mocked issue content"}}}}
        end,
        issue_comment_threads: fn "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
                                  "71ee683d-74e4-4668-95f7-537af7734054" ->
          {:ok, @comprehensive_thread}
        end do
        assert {:ok, attrs} = LinearHandler.build_agent_attributes(event, user, repository)

        assert attrs.user_id == user.id
        assert attrs.source == :linear
        assert attrs.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"
        assert attrs.external_ids["linear_comment_id"] == "66bd6984-9908-4adf-9f7b-64b1cb23c88b"

        assert attrs.external_ids["linear_parent_comment_id"] ==
                 "33250e31-de7a-4e93-9bab-7800ee1a4028"

        assert attrs.repository.id == repository.id

        assert String.contains?(
                 attrs.context,
                 "mentioned in reply comment 66bd6984-9908-4adf-9f7b-64b1cb23c88b (parent comment ID: 33250e31-de7a-4e93-9bab-7800ee1a4028)"
               )

        assert String.contains?(attrs.context, "@swarmdev reply")
        assert String.contains?(attrs.context, "TEST6")
        assert String.contains?(attrs.context, "test6reply")
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
        assert attrs.external_ids["linear_issue_id"] == "71ee683d-74e4-4668-95f7-537af7734054"
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
        assert attrs.external_ids["linear_document_id"] == "f433ebff-9cd0-4057-867a-2ab6e528a12d"
        assert attrs.repository.id == repository.id
        assert String.contains?(attrs.context, "Test doc")
        assert String.contains?(attrs.context, "This is a test document content")
      end
    end
  end

  describe "Swarm.Services.Linear.create_comment/3 and /4" do
    test "creates a parent comment on an issue" do
      with_mock Swarm.Services.Linear,
        create_comment: fn "app_user_id", "issue_id", "Test parent comment" ->
          {:ok,
           %{
             "commentCreate" => %{
               "comment" => %{"id" => "c123", "body" => "Test parent comment"},
               "success" => true
             }
           }}
        end do
        assert {:ok,
                %{
                  "commentCreate" => %{
                    "comment" => %{"id" => "c123", "body" => "Test parent comment"},
                    "success" => true
                  }
                }} =
                 Swarm.Services.Linear.create_comment(
                   "app_user_id",
                   "issue_id",
                   "Test parent comment"
                 )
      end
    end

    test "creates a reply comment on an issue" do
      with_mock Swarm.Services.Linear,
        create_comment: fn "app_user_id", "issue_id", "Test reply comment", "parent_id" ->
          {:ok,
           %{
             "commentCreate" => %{
               "comment" => %{"id" => "c456", "body" => "Test reply comment"},
               "success" => true
             }
           }}
        end do
        assert {:ok,
                %{
                  "commentCreate" => %{
                    "comment" => %{"id" => "c456", "body" => "Test reply comment"},
                    "success" => true
                  }
                }} =
                 Swarm.Services.Linear.create_comment(
                   "app_user_id",
                   "issue_id",
                   "Test reply comment",
                   "parent_id"
                 )
      end
    end
  end
end
