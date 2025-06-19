import { queryOptions } from '@tanstack/react-query'
import { temporaryToken } from '../../services/authed-auth'

export const temporaryTokenQuery = () =>
  queryOptions({
    queryKey: ['auth', 'temporary-token'],
    queryFn: () => temporaryToken(),
    staleTime: 1000 * 60 * 60 * 1, // 1 hour
    gcTime: 1000 * 60 * 60 * 1, // 1 hour
  })
