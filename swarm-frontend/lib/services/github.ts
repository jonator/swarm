'use server'

import { apiClientWithAuth } from '@/lib/client/authed'

type Installation = {
  id: number
  app_id: number
  app_slug: string
  target_id: number
  account: {
    login: string
    id: number
    avatar_url: string
    html_url: string
  }
  repository_selection: string
  created_at: string
  updated_at: string
  permissions: {
    contents: string
    metadata: string
    pull_requests: string
  }
  events: string[]
  html_url: string
}

type InstallationsResponse = {
  installations: Installation[]
  total_count: number
}

export async function getInstallations() {
  return apiClientWithAuth
    .get('github/installations')
    .json<InstallationsResponse>()
}

export type Repository = {
  mirror_url: string | null
  pushed_at: string
  svn_url: string
  open_issues_count: number
  forks_url: string
  watchers_count: number
  issues_url: string
  disabled: boolean
  collaborators_url: string
  has_wiki: boolean
  statuses_url: string
  homepage: string
  full_name: string
  stargazers_count: number
  subscription_url: string
  stargazers_url: string
  events_url: string
  has_projects: boolean
  archive_url: string
  commits_url: string
  merges_url: string
  downloads_url: string
  blobs_url: string
  comments_url: string
  contributors_url: string
  subscribers_url: string
  git_tags_url: string
  updated_at: string
  issue_events_url: string
  visibility: string
  description: string
  name: string
  id: number
  labels_url: string
  branches_url: string
  private: boolean
  issue_comment_url: string
  releases_url: string
  notifications_url: string
  hooks_url: string
  default_branch: string
  web_commit_signoff_required: boolean
  teams_url: string
  topics: string[]
  compare_url: string
  deployments_url: string
  git_url: string
  git_refs_url: string
  pulls_url: string
  url: string
  has_issues: boolean
  contents_url: string
  size: number
  owner: {
    avatar_url: string
    events_url: string
    followers_url: string
    following_url: string
    gists_url: string
    gravatar_id: string
    html_url: string
    id: number
    login: string
    node_id: string
    organizations_url: string
    received_events_url: string
    repos_url: string
    site_admin: boolean
    starred_url: string
    subscriptions_url: string
    type: string
    url: string
    user_view_type: string
  }
  git_commits_url: string
  tags_url: string
  permissions: {
    admin: boolean
    maintain: boolean
    pull: boolean
    push: boolean
    triage: boolean
  }
  language: string
  fork: boolean
  has_discussions: boolean
  watchers: number
  html_url: string
  open_issues: number
  is_template: boolean
  node_id: string
  milestones_url: string
  license: string | null
  forks_count: number
  allow_forking: boolean
  has_pages: boolean
  trees_url: string
  ssh_url: string
  assignees_url: string
  clone_url: string
  forks: number
  archived: boolean
  keys_url: string
  has_downloads: boolean
  created_at: string
  languages_url: string
}

export async function getRepositories() {
  return apiClientWithAuth.get('github/repositories').json<Repository[]>()
}

// export type Tree = {
//   mode: string
//   path: string
//   sha: string
//   type: string
//   url: string
// }

// type Trees = {
//   sha: string
//   url: string
//   tree: Tree[]
// }

//  const getRepositoryTrees = (
//   owner: string,
//   repo: string,
//   branch = 'main',
// ) =>
//   apiClientWithAuth
//     .get('github/repositories/git/trees', {
//       searchParams: { owner, repo, branch },
//     })
//     .json<Trees>()

type DetectedFramework = {
  type: 'nextjs'
  typeName: string
  path: string
  name: string
  icon: string
}

export async function getRepositoryFrameworks(
  owner: string,
  repo: string,
  branch = 'main',
) {
  const frameworks = await apiClientWithAuth
    .get('github/repositories/frameworks', {
      searchParams: { owner, repo, branch },
    })
    .json<Omit<DetectedFramework, 'icon'>[]>()

  return frameworks.map((framework) => {
    if (framework.type === 'nextjs') {
      return { ...framework, typeName: 'Next.js', icon: '/nextjs-icon.svg' }
    }

    throw new Error(`Unsupported framework type: ${framework.type}`)
  })
}
