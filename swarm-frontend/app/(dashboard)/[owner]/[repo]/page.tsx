import { Header } from '@/app/(dashboard)/header'
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
        <Header title={repo} description={`Repository in ${owner}`} />

        {/* Content will be implemented later */}
      </main>
    </>
  )
}
