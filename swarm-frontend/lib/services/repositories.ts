'use server'

import { apiClientWithAuth } from '@/lib/client/authed'
import type { Project } from './projects'

export type Repository = {
  id: number
  name: string
  owner: string
  linear_team_external_ids: string[]
  created_at: string
  updated_at: string
}

type RepositoriesResponse = {
  repositories: Repository[]
}

export async function getRepositories() {
  return apiClientWithAuth.get('repositories').json<RepositoriesResponse>()
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
    .json<RepositoriesResponse>()
}

export async function getRepositoryById(id: number) {
  return apiClientWithAuth
    .get(`repositories/${id}`)
    .json<{ repository: Repository }>()
}
