import { useQuery } from '@tanstack/react-query'
import { organizationsQuery } from '../keys/organizations'

export const useOrganizations = () => {
  return useQuery(organizationsQuery())
}
