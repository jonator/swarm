import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function RepoPage({
  params,
}: { params: Promise<{ owner: string; repo: string }> }) {
  const { owner, repo } = await params
  const { data: user } = await getUser()

  console.log(repo)

  return (
    <>
      <Navbar
        user={user}
        tabs={[
          { label: 'Dashboard', href: `/dashboard/${owner}/${repo}` },
          { label: 'Issues', href: `/dashboard/${owner}/${repo}/issues` },
          { label: 'Pull Requests', href: `/dashboard/${owner}/${repo}/pulls` },
          { label: 'Settings', href: `/dashboard/${owner}/${repo}/settings` },
        ]}
      />

      <div className='w-full max-w-sm'>
        This is repo {owner}/{repo}
      </div>
    </>
  )
}
