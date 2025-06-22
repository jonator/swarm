import { AgentsList } from '@/components/agents'
import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function OwnerAgentsPage({
  params,
}: { params: Promise<{ owner: string; repo: string }> }) {
  const { owner, repo } = await params
  const { user } = await getUser()

  return (
    <>
      <Navbar
        user={user}
        pathname={`/${owner}/${repo}/agents`}
        tabs={[
          { label: 'Overview', href: `/${owner}/${repo}` },
          {
            label: 'Agents',
            href: `/${owner}/${repo}/agents`,
            active: true,
          },
          {
            label: 'Settings',
            href: `/${owner}/${repo}/settings`,
          },
        ]}
      />

      <div className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <h1 className='text-2xl font-bold'>Agents</h1>
          <p className='text-muted-foreground'>
            All agents across repositories for {owner}
          </p>
        </div>

        <AgentsList organization_name={owner} repository_name={repo} />
      </div>
    </>
  )
}
