import { queryOptions } from '@tanstack/react-query'
import {
  type RepositoriesRequest,
  getRepositories,
} from '../../services/repositories'

export const repositoriesQuery = (params?: RepositoriesRequest) =>
  queryOptions({
    queryKey: params ? ['repositories', params.owner] : ['repositories'],
    queryFn: () => getRepositories(params),
    staleTime: 30_000, // 30 seconds
  })
