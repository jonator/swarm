import { routeEntry } from '@/actions/routing'

export default async function DashboardPage() {
  await routeEntry()

  return (
    <div className='bg-background flex min-h-svh flex-col items-center justify-center gap-6 p-6 md:p-10'>
      <div className='w-full max-w-sm'>I'm in the dashboard!</div>
    </div>
  )
}
