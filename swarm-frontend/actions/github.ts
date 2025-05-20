'use server'

import {
  type Repository,
  getRepositoryFrameworks as getRepositoryFrameworksService,
} from '@/lib/services/github'

export async function getRepositoryFrameworks(repository: Repository) {
  return await getRepositoryFrameworksService(
    repository.owner.login,
    repository.name,
    repository.default_branch,
  )
}
