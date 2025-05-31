import { queryOptions } from '@tanstack/react-query'
import { getLinearOrganization } from '../../services/linear'

export const linearOrganizationQuery = () =>
  queryOptions({
    queryKey: ['linear-organization'],
    queryFn: () => getLinearOrganization(),
    staleTime: 30_000, // 30 seconds
  })
