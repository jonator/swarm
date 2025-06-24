import { queryOptions } from '@tanstack/react-query'
import {
  type GetRepositoriesParams,
  getRepositories,
  getRepository,
} from '../../services/repositories'

export const repositoriesQuery = (params?: GetRepositoriesParams) =>
  queryOptions({
    queryKey: params?.owner
      ? ['repositories', params.owner, 'list']
      : ['repositories', 'list'],
    queryFn: () => getRepositories(params),
    staleTime: 30_000, // 30 seconds
  })

export const repositoryQuery = (id: number) =>
  queryOptions({
    queryKey: ['repository', id.toString()],
    queryFn: () => getRepository(id),
    staleTime: 30_000, // 30 seconds
  })
