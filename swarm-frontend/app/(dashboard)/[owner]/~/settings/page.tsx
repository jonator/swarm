import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function OwnerSettingsPage({
  params,
}: { params: Promise<{ owner: string }> }) {
  const { owner } = await params
  const { data: user } = await getUser()

  return (
    <>
      <Navbar
        user={user}
        tabs={[
          { label: 'Overview', href: `/${owner}` },
          { label: 'Agents', href: `/${owner}/~/agents` },
          { label: 'Settings', href: `/${owner}/~/settings` },
        ]}
      />

      <div className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <div>
            <h1 className='text-2xl font-bold'>Settings</h1>
            <p className='text-muted-foreground'>Manage settings for {owner}</p>
          </div>
        </div>

        {/* Content will be implemented later */}
      </div>
    </>
  )
}
