import { getQueryClient } from '@/config/tanstack-query'
import { temporaryTokenQuery } from '@/lib/queries/keys/auth'
import { repositoriesQuery } from '@/lib/queries/keys/repositories'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  // Prefetch and hydrate query data for dashboard
  const queryClient = getQueryClient()
  const prefetches: Promise<void>[] = [
    queryClient.prefetchQuery(repositoriesQuery()),
    queryClient.prefetchQuery(temporaryTokenQuery()),
  ]

  await Promise.all(prefetches)

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      {children}
    </HydrationBoundary>
  )
}
