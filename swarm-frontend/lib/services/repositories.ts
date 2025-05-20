import { apiClientWithAuth } from '@/lib/client/authed'

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

export const getRepositories = async () =>
  apiClientWithAuth.get('users/repositories').json<RepositoriesResponse>()
