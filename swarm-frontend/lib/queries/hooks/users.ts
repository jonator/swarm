import { useQuery } from '@tanstack/react-query'
import { usersQuery } from '../keys/users'

export const useUser = (id?: number) =>
  useQuery({
    ...usersQuery({ id }),
    select: (data) => data.user,
    enabled: !!id,
  })
