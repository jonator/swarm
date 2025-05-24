import { useQuery } from '@tanstack/react-query'
import { repositoriesQuery } from '../keys/repositories'

export const useRepositories = () => {
  return useQuery({
    ...repositoriesQuery(),
    select: (data) => data.repositories,
  })
}
