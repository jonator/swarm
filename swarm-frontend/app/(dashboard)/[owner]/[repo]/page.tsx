import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function RepoPage({
  params,
}: {
  params: Promise<{ owner: string; repo: string }>
}) {
  const [{ owner, repo }, { user }] = await Promise.all([params, getUser()])

  return (
    <>
      <Navbar
        user={user}
        pathname={`/${owner}/${repo}`}
        tabs={[
          { label: 'Overview', href: `/${owner}/${repo}`, active: true },
          { label: 'Agents', href: `/${owner}/${repo}/agents` },
          { label: 'Settings', href: `/${owner}/${repo}/settings` },
        ]}
      />

      <main className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <div>
            <h1 className='text-2xl font-bold'>{repo}</h1>
            <p className='text-muted-foreground'>Repository in {owner}</p>
          </div>
        </div>

        {/* Content will be implemented later */}
      </main>
    </>
  )
}
