import { AgentsList } from '@/components/agents'
import Navbar from '@/components/navbar'
import { getQueryClient } from '@/config/tanstack-query'
import { agentsQuery } from '@/lib/queries/keys/agents'
import { getUser } from '@/lib/services/users'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'

export default async function OwnerAgentsPage({
  params,
}: { params: Promise<{ owner: string }> }) {
  const { owner } = await params
  const { user } = await getUser()
  const now = new Date()

  const queryClient = getQueryClient()
  await queryClient.prefetchQuery(agentsQuery({ organization_name: owner }))

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <Navbar
        user={user}
        pathname={`/${owner}`}
        tabs={[
          { label: 'Overview', href: `/${owner}` },
          { label: 'Agents', href: `/${owner}/~/agents`, active: true },
          { label: 'Settings', href: `/${owner}/~/settings` },
        ]}
      />

      <div className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <h1 className='text-2xl font-bold'>Agents</h1>
          <p className='text-muted-foreground'>
            All agents across repositories for {owner}
          </p>
        </div>

        <AgentsList organization_name={owner} now={now} />
      </div>
    </HydrationBoundary>
  )
}
