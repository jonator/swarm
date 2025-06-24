'use server'

import { apiClientWithAuth } from '@/lib/client/authed'
import type { Project } from './projects'

export type Repository = {
  id: number
  name: string
  owner: string
  organization_id: number
  linear_team_external_ids: string[]
  created_at: string
  updated_at: string
}

export type GetRepositoriesParams = {
  owner: string
}

export async function getRepositories(params?: GetRepositoriesParams) {
  if (params && 'owner' in params) {
    return apiClientWithAuth
      .get('repositories', { searchParams: { owner: params.owner! } })
      .json<{
        repositories: Repository[]
      }>()
  }

  return apiClientWithAuth.get('repositories').json<{
    repositories: Repository[]
  }>()
}

export async function getRepository(id: number) {
  return apiClientWithAuth
    .get(`repositories/${id}`)
    .json<{ repository: Repository }>()
}

export type CreateRepositoryParams =
  | {
      name: string
      owner: string
      projects?: Project[]
    }
  | {
      github_repo_id: number
      projects?: Project[]
    }

export async function createRepository(params: CreateRepositoryParams) {
  if ('github_repo_id' in params) {
    return apiClientWithAuth
      .post('repositories', { json: params })
      .json<{ repository: Repository }>()
  }
  return apiClientWithAuth
    .post('repositories', { json: { repository: params } })
    .json<{ repository: Repository }>()
}

export async function updateRepository(
  params: Partial<Repository> & { id: number },
) {
  return apiClientWithAuth
    .patch(`repositories/${params.id}`, { json: params })
    .json<{ repository: Repository }>()
}

export async function migrateRepositories() {
  return apiClientWithAuth
    .post('repositories/migrate')
    .json<{ repositories: Repository[] }>()
}
