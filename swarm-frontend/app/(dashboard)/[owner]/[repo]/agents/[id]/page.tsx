import { AgentDisplay } from '@/components/agents/agent'
import { AgentBreadcrumb } from '@/components/agents/status'
import Navbar from '@/components/navbar'
import { getQueryClient } from '@/config/tanstack-query'
import { agentQuery } from '@/lib/queries/keys/agents'
import { getAgent } from '@/lib/services/agents'
import { getUser } from '@/lib/services/users'
import { getNow } from '@/lib/utils/date'
import { HydrationBoundary, dehydrate } from '@tanstack/react-query'
import { headers } from 'next/headers'

export default async function AgentPage({
  params,
}: { params: Promise<{ owner: string; repo: string; id: string }> }) {
  const [{ owner, repo, id }, { user }, headerList] = await Promise.all([
    params,
    getUser(),
    headers(),
  ])

  const now = getNow()
  const timeZone =
    headerList.get('x-vercel-ip-timezone') ??
    Intl.DateTimeFormat().resolvedOptions().timeZone

  const { agent } = await getAgent(id)

  const queryClient = getQueryClient()

  queryClient.setQueryData(agentQuery(id).queryKey, { agent })
  await queryClient.prefetchQuery(agentQuery(id))

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <Navbar
        user={user}
        pathname={`/${owner}/${repo}/agents/${id}`}
        tabs={[
          {
            label: 'Agent',
            href: `/${owner}/${repo}/agents/${id}`,
            active: true,
          },
        ]}
        breadcrumb={<AgentBreadcrumb id={id} />}
      />

      <main className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <h1 className='text-2xl font-bold'>{agent.name}</h1>
          <p className='text-muted-foreground'>
            All agents across repositories for {owner}
          </p>
        </div>

        <AgentDisplay id={id} now={now} timeZone={timeZone} />
      </main>
    </HydrationBoundary>
  )
}
