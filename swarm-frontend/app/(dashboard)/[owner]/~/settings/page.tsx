import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function OwnerSettingsPage({
  params,
}: { params: Promise<{ owner: string }> }) {
  const [{ owner }, { user }] = await Promise.all([params, getUser()])

  return (
    <>
      <Navbar
        user={user}
        pathname={`/${owner}`}
        tabs={[
          { label: 'Overview', href: `/${owner}` },
          { label: 'Agents', href: `/${owner}/~/agents` },
          { label: 'Settings', href: `/${owner}/~/settings`, active: true },
        ]}
      />

      <main className='dashboard-container'>
        <div className='flex items-center justify-between'>
          <div>
            <h1 className='text-2xl font-bold'>Settings</h1>
            <p className='text-muted-foreground'>Manage settings for {owner}</p>
          </div>
        </div>

        {/* Content will be implemented later */}
      </main>
    </>
  )
}
