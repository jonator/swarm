import { routeEntry } from '@/actions/routing'
import { Home as HomeContent } from '@/components/home'
import { authGuard } from '@/lib/client/authed'

export default async function Home() {
  // Redirect to the dashboard if the user is authenticated, but don't redirect to login otherwise
  const token = await authGuard({ redirect: false })
  if (token) await routeEntry()

  return <HomeContent />
}
