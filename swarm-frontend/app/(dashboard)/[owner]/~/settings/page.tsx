import { Header } from '@/app/(dashboard)/header'
import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function OwnerSettingsPage({
  params,
}: {
  params: Promise<{ owner: string }>
}) {
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
        <Header title='Settings' description={`Settings for ${owner}`} />

        {/* Content will be implemented later */}
      </main>
    </>
  )
}
