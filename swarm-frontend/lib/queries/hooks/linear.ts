import { useQuery } from '@tanstack/react-query'
import { linearOrganizationQuery } from '../keys/linear'

export const useLinearOrganization = (options?: { enabled?: boolean }) =>
  useQuery({
    ...linearOrganizationQuery(),
    enabled: options?.enabled ?? true,
  })
