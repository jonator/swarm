import { queryOptions } from '@tanstack/react-query'
import { type GetUserParams, getUser } from '@/lib/services/users'

export const usersQuery = (params: GetUserParams = {}) =>
  queryOptions({
    queryKey: params.id ? ['users', params.id.toString()] : ['users', 'list'],
    queryFn: () => getUser(params),
  })
