import { type GetUserParams, getUser } from '@/lib/services/users'
import { queryOptions } from '@tanstack/react-query'

export const usersQuery = (params: GetUserParams = {}) =>
  queryOptions({
    queryKey: params.id ? ['users', params.id.toString()] : ['users', 'list'],
    queryFn: () => getUser(params),
  })
