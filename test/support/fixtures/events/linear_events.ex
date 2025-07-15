defmodule Swarm.LinearEventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Swarm.Events` context.
  """

  def linear_user_fixture() do
    Swarm.AccountsFixtures.user_fixture(%{
      email: "jonathanator0@gmail.com",
      username: "jonator",
      avatar_url:
        "https://public.linear.app/f15f0e68-9424-4add-b7c6-1d318e455719/79589ad0-a8cf-4250-829c-807be084c051"
    })
  end

  def linear_user_repository_fixture() do
    user = linear_user_fixture()

    Swarm.RepositoriesFixtures.repository_fixture(user, %{
      name: "Swarm",
      external_id: "github:9999999",
      linear_team_external_ids: ["2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2"]
    })
  end

  def linear_issue_description_mention_params() do
    Jason.decode!("""
    {
      "action": "issueMention",
      "appUserId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
      "createdAt": "2025-05-31T19:09:49.248Z",
      "notification": {
        "actor": {
          "avatarUrl": "https://public.linear.app/f15f0e68-9424-4add-b7c6-1d318e455719/79589ad0-a8cf-4250-829c-807be084c051",
          "email": "jonathanator0@gmail.com",
          "id": "f15f0e68-9424-4add-b7c6-1d318e455719",
          "name": "Jonathan Ator",
          "url": "https://linear.app/swarmai/profiles/jonathanator0"
        },
        "actorId": "f15f0e68-9424-4add-b7c6-1d318e455719",
        "archivedAt": null,
        "createdAt": "2025-05-31T19:09:49.178Z",
        "emailedAt": null,
        "externalUserActorId": null,
        "id": "40ddd14f-971f-4d93-af97-04834d8cf061",
        "issue": {
          "description": "Hey thanks for the great description! Great. Greaasdl;kjf;alsjkdft. Thanks\\n\\n@swarm-ai-dev",
          "id": "71ee683d-74e4-4668-95f7-537af7734054",
          "identifier": "SW-10",
          "team": {
            "id": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
            "key": "SW",
            "name": "Swarm"
          },
          "teamId": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
          "title": "Improve README",
          "url": "https://linear.app/swarmai/issue/SW-10/improve-readme"
        },
        "issueId": "71ee683d-74e4-4668-95f7-537af7734054",
        "readAt": null,
        "snoozedUntilAt": null,
        "type": "issueMention",
        "unsnoozedAt": null,
        "updatedAt": "2025-05-31T19:09:49.178Z",
        "userId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
      },
      "oauthClientId": "766dc2d9-8ff7-4bc8-bf2b-c6e2ce32cb72",
      "organizationId": "4fde7f37-de48-4d5c-93fb-473c8f24d4cb",
      "type": "AppUserNotification",
      "webhookId": "d86e55d2-acb2-4ba5-bdc5-78368417c3a8",
      "webhookTimestamp": 1748718589311
    }
    """)
  end

  def linear_issue_assigned_to_swarm_params() do
    Jason.decode!("""
    {
      "action": "issueAssignedToYou",
      "appUserId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
      "createdAt": "2025-05-31T19:13:10.065Z",
      "notification": {
        "actor": {
          "avatarUrl": "https://public.linear.app/f15f0e68-9424-4add-b7c6-1d318e455719/79589ad0-a8cf-4250-829c-807be084c051",
          "email": "jonathanator0@gmail.com",
          "id": "f15f0e68-9424-4add-b7c6-1d318e455719",
          "name": "Jonathan Ator",
          "url": "https://linear.app/swarmai/profiles/jonathanator0"
        },
        "actorId": "f15f0e68-9424-4add-b7c6-1d318e455719",
        "archivedAt": null,
        "createdAt": "2025-05-31T19:13:10.037Z",
        "emailedAt": null,
        "externalUserActorId": null,
        "id": "8ff7ef66-6969-456e-8df2-188d405a7cbe",
        "issue": {
          "id": "71ee683d-74e4-4668-95f7-537af7734054",
          "identifier": "SW-10",
          "team": {
            "id": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
            "key": "SW",
            "name": "Swarm"
          },
          "teamId": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
          "title": "Improve README",
          "url": "https://linear.app/swarmai/issue/SW-10/improve-readme"
        },
        "issueId": "71ee683d-74e4-4668-95f7-537af7734054",
        "readAt": null,
        "snoozedUntilAt": null,
        "type": "issueAssignedToYou",
        "unsnoozedAt": null,
        "updatedAt": "2025-05-31T19:13:10.037Z",
        "userId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
      },
      "oauthClientId": "766dc2d9-8ff7-4bc8-bf2b-c6e2ce32cb72",
      "organizationId": "4fde7f37-de48-4d5c-93fb-473c8f24d4cb",
      "type": "AppUserNotification",
      "webhookId": "d86e55d2-acb2-4ba5-bdc5-78368417c3a8",
      "webhookTimestamp": 1748718790250
    }
    """)
  end

  def linear_issue_comment_mention_params() do
    Jason.decode!("""
    {
    "action": "issueCommentMention",
    "appUserId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
    "createdAt": "2025-05-31T19:16:08.723Z",
    "notification": {
      "actor": {
        "avatarUrl": "https://public.linear.app/f15f0e68-9424-4add-b7c6-1d318e455719/79589ad0-a8cf-4250-829c-807be084c051",
        "email": "jonathanator0@gmail.com",
        "id": "f15f0e68-9424-4add-b7c6-1d318e455719",
        "name": "Jonathan Ator",
        "url": "https://linear.app/swarmai/profiles/jonathanator0"
      },
      "actorId": "f15f0e68-9424-4add-b7c6-1d318e455719",
      "archivedAt": null,
      "comment": {
        "body": "This is a mention comment @swarm-ai-dev ",
        "id": "1572d3ac-fca9-4713-84e3-4a104c6674fd",
        "issueId": "71ee683d-74e4-4668-95f7-537af7734054",
        "userId": "f15f0e68-9424-4add-b7c6-1d318e455719"
      },
      "commentId": "1572d3ac-fca9-4713-84e3-4a104c6674fd",
      "createdAt": "2025-05-31T19:16:08.692Z",
      "emailedAt": null,
      "externalUserActorId": null,
      "id": "f1145df5-0207-48fb-91ef-62eba67ddb36",
      "issue": {
        "id": "71ee683d-74e4-4668-95f7-537af7734054",
        "identifier": "SW-10",
        "team": {
          "id": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
          "key": "SW",
          "name": "Swarm"
        },
        "teamId": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
        "title": "Improve README",
        "url": "https://linear.app/swarmai/issue/SW-10/improve-readme"
      },
      "issueId": "71ee683d-74e4-4668-95f7-537af7734054",
      "readAt": null,
      "snoozedUntilAt": null,
      "type": "issueCommentMention",
      "unsnoozedAt": null,
      "updatedAt": "2025-05-31T19:16:08.692Z",
      "userId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
    },
    "oauthClientId": "766dc2d9-8ff7-4bc8-bf2b-c6e2ce32cb72",
    "organizationId": "4fde7f37-de48-4d5c-93fb-473c8f24d4cb",
    "type": "AppUserNotification",
    "webhookId": "d86e55d2-acb2-4ba5-bdc5-78368417c3a8",
    "webhookTimestamp": 1748718968791
    }
    """)
  end

  def linear_document_mention_params() do
    Jason.decode!("""
    {
    "action": "documentMention",
    "appUserId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
    "createdAt": "2025-05-31T21:52:43.625Z",
    "notification": {
      "actor": {
        "avatarUrl": "https://public.linear.app/f15f0e68-9424-4add-b7c6-1d318e455719/79589ad0-a8cf-4250-829c-807be084c051",
        "email": "jonathanator0@gmail.com",
        "id": "f15f0e68-9424-4add-b7c6-1d318e455719",
        "name": "Jonathan Ator",
        "url": "https://linear.app/swarmai/profiles/jonathanator0"
      },
      "actorId": "f15f0e68-9424-4add-b7c6-1d318e455719",
      "archivedAt": null,
      "createdAt": "2025-05-31T21:52:43.596Z",
      "document": {
        "id": "f433ebff-9cd0-4057-867a-2ab6e528a12d",
        "project": {
          "id": "bd51cbd8-589f-4122-8326-4347fb0c89ce",
          "name": "Test project",
          "url": "https://linear.app/swarmai/project/test-project-3f0905925071"
        },
        "projectId": "bd51cbd8-589f-4122-8326-4347fb0c89ce",
        "title": "Test doc"
      },
      "documentId": "f433ebff-9cd0-4057-867a-2ab6e528a12d",
      "emailedAt": null,
      "externalUserActorId": null,
      "id": "540899ec-b1a0-44fe-873f-f1ad047cfd72",
      "readAt": null,
      "snoozedUntilAt": null,
      "type": "documentMention",
      "unsnoozedAt": null,
      "updatedAt": "2025-05-31T21:52:43.596Z",
      "userId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
    },
    "oauthClientId": "766dc2d9-8ff7-4bc8-bf2b-c6e2ce32cb72",
    "organizationId": "4fde7f37-de48-4d5c-93fb-473c8f24d4cb",
    "type": "AppUserNotification",
    "webhookId": "d86e55d2-acb2-4ba5-bdc5-78368417c3a8",
    "webhookTimestamp": 1748728363638
    }
    """)
  end

  def linear_issue_new_comment_params() do
    Jason.decode!("""
    {
    "action": "issueNewComment",
    "appUserId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
    "createdAt": "2025-06-07T14:44:02.832Z",
    "notification": {
      "actor": {
        "avatarUrl": "https://public.linear.app/f15f0e68-9424-4add-b7c6-1d318e455719/79589ad0-a8cf-4250-829c-807be084c051",
        "email": "jonathanator0@gmail.com",
        "id": "f15f0e68-9424-4add-b7c6-1d318e455719",
        "name": "Jonathan Ator",
        "url": "https://linear.app/swarmai/profiles/jonathanator0"
      },
      "actorId": "f15f0e68-9424-4add-b7c6-1d318e455719",
      "archivedAt": null,
      "comment": {
        "body": "We should look into this at some point",
        "id": "ff7ece6b-be23-4c5d-a13b-76ae72ea43d8",
        "issueId": "71ee683d-74e4-4668-95f7-537af7734054",
        "userId": "f15f0e68-9424-4add-b7c6-1d318e455719"
      },
      "commentId": "ff7ece6b-be23-4c5d-a13b-76ae72ea43d8",
      "createdAt": "2025-06-07T14:44:02.784Z",
      "externalUserActorId": null,
      "id": "cb7f083d-6211-47e0-aaca-466bda938fd5",
      "issue": {
        "id": "71ee683d-74e4-4668-95f7-537af7734054",
        "identifier": "SW-10",
        "team": {
          "id": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
          "key": "SW",
          "name": "Swarm"
        },
        "teamId": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
        "title": "Improve README",
        "url": "https://linear.app/swarmai/issue/SW-10/improve-readme"
      },
      "issueId": "71ee683d-74e4-4668-95f7-537af7734054",
      "type": "issueNewComment",
      "updatedAt": "2025-06-07T14:44:02.784Z",
      "userId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
    },
    "oauthClientId": "766dc2d9-8ff7-4bc8-bf2b-c6e2ce32cb72",
    "organizationId": "4fde7f37-de48-4d5c-93fb-473c8f24d4cb",
    "type": "AppUserNotification",
    "webhookId": "9f8226e3-6bd3-4e54-aa94-df511f0e4b7e",
    "webhookTimestamp": 1749307442902
    }
    """)
  end

  def linear_issue_new_child_comment_mention_params() do
    Jason.decode!("""
    {
    "action": "issueCommentMention",
    "appUserId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
    "createdAt": "2025-06-16T01:05:17.491Z",
    "notification": {
      "actor": {
        "avatarUrl": "https://public.linear.app/f15f0e68-9424-4add-b7c6-1d318e455719/79589ad0-a8cf-4250-829c-807be084c051",
        "email": "jonathanator0@gmail.com",
        "id": "f15f0e68-9424-4add-b7c6-1d318e455719",
        "name": "Jonathan Ator",
        "url": "https://linear.app/swarmai/profiles/jonathanator0"
      },
      "actorId": "f15f0e68-9424-4add-b7c6-1d318e455719",
      "archivedAt": null,
      "comment": {
        "body": "@swarm-ai-dev reply",
        "id": "66bd6984-9908-4adf-9f7b-64b1cb23c88b",
        "issueId": "71ee683d-74e4-4668-95f7-537af7734054",
        "userId": "f15f0e68-9424-4add-b7c6-1d318e455719"
      },
      "commentId": "66bd6984-9908-4adf-9f7b-64b1cb23c88b",
      "createdAt": "2025-06-16T01:05:17.460Z",
      "externalUserActorId": null,
      "id": "26804024-df66-4181-aeab-523f5aff0d0d",
      "issue": {
        "id": "71ee683d-74e4-4668-95f7-537af7734054",
        "identifier": "SW-10",
        "team": {
          "id": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
          "key": "SW",
          "name": "Swarm"
        },
        "teamId": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
        "title": "Improve README",
        "url": "https://linear.app/swarmai/issue/SW-10/improve-readme"
      },
      "issueId": "71ee683d-74e4-4668-95f7-537af7734054",
      "parentComment": {
        "body": "TEST6",
        "id": "33250e31-de7a-4e93-9bab-7800ee1a4028",
        "issueId": "71ee683d-74e4-4668-95f7-537af7734054",
        "userId": "f15f0e68-9424-4add-b7c6-1d318e455719"
      },
      "parentCommentId": "33250e31-de7a-4e93-9bab-7800ee1a4028",
      "type": "issueCommentMention",
      "updatedAt": "2025-06-16T01:05:17.460Z",
      "userId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
    },
    "oauthClientId": "766dc2d9-8ff7-4bc8-bf2b-c6e2ce32cb72",
    "organizationId": "4fde7f37-de48-4d5c-93fb-473c8f24d4cb",
    "type": "AppUserNotification",
    "webhookId": "93acd642-4e76-4d91-ba82-8e6cb2700a3b",
    "webhookTimestamp": 1750035917528
    }
    """)
  end

  @spec linear_issue_new_child_comment_of_app_parent_params() :: any()
  def linear_issue_new_child_comment_of_app_parent_params() do
    Jason.decode!("""
    {
      "action": "issueNewComment",
      "appUserId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd",
      "createdAt": "2025-06-28T00:22:28.266Z",
      "notification": {
        "actor": {
          "avatarUrl": "https://public.linear.app/f15f0e68-9424-4add-b7c6-1d318e455719/79589ad0-a8cf-4250-829c-807be084c051",
          "email": "jonathanator0@gmail.com",
          "id": "f15f0e68-9424-4add-b7c6-1d318e455719",
          "name": "Jonathan Ator",
          "url": "https://linear.app/swarmai/profiles/jonathanator0"
        },
        "actorId": "f15f0e68-9424-4add-b7c6-1d318e455719",
        "archivedAt": null,
        "comment": {
          "body": "Simplify",
          "id": "82736cf1-a67c-48d7-b532-234c556831f9",
          "issueId": "19e7fc32-f536-4bbc-8f44-e679c6b95580",
          "userId": "f15f0e68-9424-4add-b7c6-1d318e455719"
        },
        "commentId": "82736cf1-a67c-48d7-b532-234c556831f9",
        "createdAt": "2025-06-28T00:22:28.234Z",
        "externalUserActorId": null,
        "id": "80e07647-66dd-42af-ac0b-5ab08571f01c",
        "issue": {
          "id": "19e7fc32-f536-4bbc-8f44-e679c6b95580",
          "identifier": "SW-12",
          "team": {
            "id": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
            "key": "SW",
            "name": "Swarm"
          },
          "teamId": "2564b0ba-7e78-4dc4-9012-bbd1e9acd1d2",
          "title": "Verify webhook event signaturess",
          "url": "https://linear.app/swarmai/issue/SW-12/verify-webhook-event-signaturess"
        },
        "issueId": "19e7fc32-f536-4bbc-8f44-e679c6b95580",
        "parentComment": {
          "body": "This is the parent comment body (test)",
          "id": "a75617f5-250a-4778-9e18-e271458e32a0",
          "issueId": "19e7fc32-f536-4bbc-8f44-e679c6b95580",
          "userId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
        },
        "parentCommentId": "a75617f5-250a-4778-9e18-e271458e32a0",
        "type": "issueNewComment",
        "updatedAt": "2025-06-28T00:22:28.234Z",
        "userId": "90e50d8f-e44e-45d9-9de3-4ec126ce78fd"
      },
      "oauthClientId": "766dc2d9-8ff7-4bc8-bf2b-c6e2ce32cb72",
      "organizationId": "4fde7f37-de48-4d5c-93fb-473c8f24d4cb",
      "type": "AppUserNotification",
      "webhookId": "8239ef6f-ea58-40d3-a7ef-3f8620b12ccd",
      "webhookTimestamp": 1751070148298
    }
    """)
  end
end
