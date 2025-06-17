import { queryOptions } from '@tanstack/react-query'
import { temporaryToken } from '../../services/authed-auth'

export const temporaryTokenQuery = () =>
  queryOptions({
    queryKey: ['auth', 'temporary-token'],
    queryFn: () => temporaryToken(),
  })
