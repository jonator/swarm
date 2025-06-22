import { useQuery } from '@tanstack/react-query'
import { getRepositoryById } from '../../services/repositories'
import { repositoriesQuery } from '../keys/repositories'

export const useRepositories = () => {
  return useQuery({
    ...repositoriesQuery(),
    select: (data) => data.repositories,
  })
}

export const useRepository = (id: number) => {
  return useQuery({
    queryKey: ['repository', id],
    queryFn: () => getRepositoryById(id),
    select: (data) => data.repository,
    enabled: !!id,
  })
}
