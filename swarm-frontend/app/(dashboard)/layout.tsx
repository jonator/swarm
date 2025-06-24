import { getQueryClient } from '@/config/tanstack-query'
import {
  repositoriesQuery,
  repositoryQuery,
} from '@/lib/queries/keys/repositories'
import { usersQuery } from '@/lib/queries/keys/users'
import { getRepositories } from '@/lib/services/repositories'
import { getUser } from '@/lib/services/users'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  // Prefetch and hydrate query data for dashboard
  const queryClient = getQueryClient()

  // Strategy to prefetch and populate data across queries
  // 1. Get data directly
  // 2. Set data in query client directly
  // 2. Call prefetch to prep for hydration and get cache hits since it was set already
  const [{ user }, repositories] = await Promise.all([
    getUser(),
    getRepositories(),
  ])

  queryClient.setQueryData(repositoriesQuery().queryKey, repositories)
  queryClient.setQueryData(usersQuery({ id: user.id }).queryKey, { user })

  const repositoryPrefetches: Promise<void>[] = []
  for (const repository of repositories.repositories) {
    queryClient.setQueryData(repositoryQuery(repository.id).queryKey, {
      repository,
    })
    repositoryPrefetches.push(
      queryClient.prefetchQuery(repositoryQuery(repository.id)),
    )
  }

  const prefetches: Promise<void>[] = [
    queryClient.prefetchQuery(repositoriesQuery()),
    queryClient.prefetchQuery(usersQuery({ id: user.id })),
    ...repositoryPrefetches,
  ]

  await Promise.all(prefetches)

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      {children}
    </HydrationBoundary>
  )
}
