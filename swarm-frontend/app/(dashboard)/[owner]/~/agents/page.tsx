import { dehydrate, HydrationBoundary } from '@tanstack/react-query'
import { headers } from 'next/headers'
import { Header } from '@/app/(dashboard)/header'
import { AgentsList } from '@/components/agents/list'
import Navbar from '@/components/navbar'
import { getQueryClient } from '@/config/tanstack-query'
import { agentsQuery } from '@/lib/queries/keys/agents'
import { getUser } from '@/lib/services/users'
import { getNow } from '@/lib/utils/date'

export default async function OwnerAgentsPage({
  params,
}: {
  params: Promise<{ owner: string }>
}) {
  const [{ owner }, { user }, headerList] = await Promise.all([
    params,
    getUser(),
    headers(),
  ])
  const now = getNow()
  const timeZone =
    headerList.get('x-vercel-ip-timezone') ??
    Intl.DateTimeFormat().resolvedOptions().timeZone

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

      <main className='dashboard-container'>
        <Header title='Agents' description={`All agents for ${owner}`} />
        <AgentsList organization_name={owner} now={now} timeZone={timeZone} />
      </main>
    </HydrationBoundary>
  )
}
