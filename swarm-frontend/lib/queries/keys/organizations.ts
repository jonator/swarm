import { queryOptions } from '@tanstack/react-query'
import { getOrganizations } from '../../services/organizations'

export const organizationsQuery = () =>
  queryOptions({
    queryKey: ['organizations', 'list'],
    queryFn: () => getOrganizations(),
    staleTime: 30_000, // 30 seconds
  })
