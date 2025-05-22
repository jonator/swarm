import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const { data: user } = await getUser()

  return (
    <div className='bg-background flex min-h-svh flex-col items-center justify-center gap-6 p-6 md:p-10'>
      <Navbar user={user} />
      {children}
    </div>
  )
}
