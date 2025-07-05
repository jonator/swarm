import { queryOptions } from '@tanstack/react-query'
import { temporaryToken } from '../../services/token'

export const temporaryTokenQuery = () =>
  queryOptions({
    queryKey: ['auth', 'temporary-token'],
    queryFn: () => temporaryToken(),
    staleTime: 60 * 60 * 1000, // 1 hour in milliseconds
  })
