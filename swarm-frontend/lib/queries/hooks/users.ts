import { useQuery } from '@tanstack/react-query'
import { usersQuery } from '../keys/users'

export function useUser(id?: number) {
  const q = usersQuery({ id }).queryKey
  console.log('useUser', q)

  const query = useQuery({
    ...usersQuery({ id }),
    enabled: !!id,
  })

  const user = query.data && 'user' in query.data ? query.data.user : undefined

  return { ...query, user }
}
