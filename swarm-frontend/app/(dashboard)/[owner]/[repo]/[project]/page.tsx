import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function ProjectPage({
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
          { label: 'Settings', href: `/${owner}/${repo}/${project}/settings` },
        ]}
      />

      <div className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <div>
            <h1 className='text-2xl font-bold'>{project}</h1>
            <p className='text-muted-foreground'>
              {owner}/{repo}
            </p>
          </div>
        </div>

        {/* Content will be implemented later */}
      </div>
    </>
  )
}
