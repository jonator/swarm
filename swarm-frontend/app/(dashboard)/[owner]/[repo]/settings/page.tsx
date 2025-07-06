import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function RepoSettingsPage({
  params,
}: { params: Promise<{ owner: string; repo: string }> }) {
  const [{ owner, repo }, { user }] = await Promise.all([params, getUser()])

  return (
    <>
      <Navbar
        user={user}
        pathname={`/${owner}/${repo}`}
        tabs={[
          { label: 'Overview', href: `/${owner}/${repo}` },
          { label: 'Agents', href: `/${owner}/${repo}/agents` },
          {
            label: 'Settings',
            href: `/${owner}/${repo}/settings`,
            active: true,
          },
        ]}
      />

      <main className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <div>
            <h1 className='text-2xl font-bold'>Repository Settings</h1>
            <p className='text-muted-foreground'>
              Manage settings for {owner}/{repo}
            </p>
          </div>
        </div>

        {/* Content will be implemented later */}
      </main>
    </>
  )
}
