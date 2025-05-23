import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function ProjectAgentsPage({
  params,
}: { params: Promise<{ owner: string; repo: string; project: string }> }) {
  const { owner, repo, project } = await params
  const { data: user } = await getUser()

  return (
    <>
      <Navbar
        user={user}
        tabs={[
          { label: 'Overview', href: `/${owner}/${repo}/${project}` },
          { label: 'Agents', href: `/${owner}/${repo}/${project}/agents` },
          { label: 'Messages', href: `/${owner}/${repo}/${project}/messages` },
          { label: 'Settings', href: `/${owner}/${repo}/${project}/settings` },
        ]}
      />

      <div className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <div>
            <h1 className='text-2xl font-bold'>Agents</h1>
            <p className='text-muted-foreground'>
              Agents for {project} in {owner}/{repo}
            </p>
          </div>
        </div>

        {/* Content will be implemented later */}
      </div>
    </>
  )
}
