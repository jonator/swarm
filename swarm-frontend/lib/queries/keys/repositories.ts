import { queryOptions } from '@tanstack/react-query'
import { getRepositories } from '../../services/repositories'

export const repositoriesQuery = () =>
  queryOptions({
    queryKey: ['repositories', 'all'],
    queryFn: () => getRepositories(),
    staleTime: 30_000, // 30 seconds
  })
