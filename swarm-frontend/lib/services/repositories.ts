'use server'

import { apiClientWithAuth } from '@/lib/client/authed'
import type { Project } from './projects'

type Repository = {
  id: number
  name: string
  owner: string
  created_at: string
  updated_at: string
}

type RepositoriesResponse = {
  repositories: Repository[]
}

export async function getRepositories() {
  return apiClientWithAuth.get('users/repositories').json<RepositoriesResponse>()
}

export type CreateRepositoryParams = {
  name: string
  owner: string
  projects?: Project[]
}

export async function createRepository(params: CreateRepositoryParams) {
  return apiClientWithAuth
    .post('users/repositories', { json: { repository: params } })
    .json<{ repository: Repository }>()
}