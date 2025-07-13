import { dehydrate, HydrationBoundary } from '@tanstack/react-query'
import { headers } from 'next/headers'
import { AgentHeader } from '@/components/agents/header'
import { AgentMessages } from '@/components/agents/messages'
import { AgentBreadcrumb } from '@/components/agents/status'
import Navbar from '@/components/navbar'
import { getQueryClient } from '@/config/tanstack-query'
import { agentQuery } from '@/lib/queries/keys/agents'
import { getAgent } from '@/lib/services/agents'
import { getUser } from '@/lib/services/users'
import { getNow } from '@/lib/utils/date'

export default async function AgentPage({
  params,
}: {
  params: Promise<{ owner: string; repo: string; id: string }>
}) {
  const { owner, repo, id } = await params

  const [{ user }, headerList, { agent }] = await Promise.all([
    getUser(),
    headers(),
    getAgent(id),
  ])

  const now = getNow()
  const timeZone =
    headerList.get('x-vercel-ip-timezone') ??
    Intl.DateTimeFormat().resolvedOptions().timeZone

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

      <main className='pt-navbar h-screen'>
        <section className='container mx-auto flex flex-col gap-4'>
          <AgentHeader agentId={id} now={now} timeZone={timeZone} />
          <AgentMessages agentId={id} />
        </section>
      </main>
    </HydrationBoundary>
  )
}
