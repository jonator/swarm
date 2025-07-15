import { Header } from '@/app/(dashboard)/header'
import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function OwnerPage({
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
          { label: 'Overview', href: `/${owner}`, active: true },
          { label: 'Agents', href: `/${owner}/~/agents` },
          { label: 'Settings', href: `/${owner}/~/settings` },
        ]}
      />

      <main className='dashboard-container'>
        <Header title={owner} description={`Organization ${owner}`} />

        {/* Content will be implemented later */}
      </main>
    </>
  )
}
