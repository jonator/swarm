import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function OwnerPage({
  params,
}: { params: Promise<{ owner: string }> }) {
  const { owner, ...rest } = await params
  const { data: user } = await getUser()

  console.log(rest)

  return (
    <>
      <Navbar
        user={user}
        tabs={[
          { label: 'Overview', href: `/${owner}`, active: true },
          { label: 'Issues', href: `/dashboard/${owner}/issues` },
          { label: 'Pull Requests', href: `/dashboard/${owner}/pulls` },
          { label: 'Settings', href: `/dashboard/${owner}/settings` },
        ]}
      />

      <div className='w-full max-w-sm'>This is repo {owner}</div>
    </>
  )
}
