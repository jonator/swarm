import { getQueryClient } from '@/config/tanstack-query'
import { repositoriesQuery } from '@/lib/queries/keys/repositories'
import { usersQuery } from '@/lib/queries/keys/users'
import { getUser } from '@/lib/services/users'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  // Prefetch and hydrate query data for dashboard
  const queryClient = getQueryClient()

  const [{ user }] = await Promise.all([
    getUser(),
    queryClient.prefetchQuery(repositoriesQuery()),
    queryClient.prefetchQuery(usersQuery({ id: (await getUser()).user.id })),
  ])

  queryClient.setQueryData(usersQuery({ id: user.id }).queryKey, { user })

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      {children}
    </HydrationBoundary>
  )
}
