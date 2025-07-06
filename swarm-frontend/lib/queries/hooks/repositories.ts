import { useQuery } from '@tanstack/react-query'
import {
  type GetRepositoriesParams,
  getRepository,
} from '../../services/repositories'
import { repositoriesQuery, repositoryQuery } from '../keys/repositories'

export const useRepositories = (params?: GetRepositoriesParams) =>
  useQuery({
    ...repositoriesQuery(params),
    select: (data) => data.repositories,
  })

export const useRepository = (id: number) =>
  useQuery({
    ...repositoryQuery(id),
    queryFn: () => getRepository(id),
    select: (data) => data.repository,
    enabled: !!id,
  })
