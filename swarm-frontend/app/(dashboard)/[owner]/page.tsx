import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function OwnerPage({
  params,
}: { params: Promise<{ owner: string }> }) {
  const { owner } = await params
  const { user } = await getUser()

  return (
    <>
      <Navbar
        user={user}
        pathname={`/${owner}`}
        tabs={[
          { label: 'Overview', href: `/${owner}`, active: true },
          { label: 'Agents', href: `/${owner}/~/agents` },
          { label: 'Settings', href: `/${owner}/~/settings` },
        ]}
      />

      <div className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <h1 className='text-2xl font-bold'>Overview</h1>
          <p className='text-muted-foreground'>
            Repositories and projects for {owner}
          </p>
        </div>

        {/* Content will be implemented later */}
      </div>
    </>
  )
}
