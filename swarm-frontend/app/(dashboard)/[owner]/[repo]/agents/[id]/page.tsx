import { AgentHeader } from '@/components/agents/header'
import { AgentBreadcrumb } from '@/components/agents/status'
import Navbar from '@/components/navbar'
import { getQueryClient } from '@/config/tanstack-query'
import { parseAgent } from '@/lib/models/agents'
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
        <AgentHeader agent={parseAgent(agent)} now={now} timeZone={timeZone} />
      </main>
    </HydrationBoundary>
  )
}
