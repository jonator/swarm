import { redirect } from 'next/navigation'
import { InstallLinear } from '@/components/onboarding/linear'
import { authGuard } from '@/lib/client/authed'
import { hasLinearAccess } from '@/lib/services/linear'
import { getRepositories } from '@/lib/services/repositories'

export default async function LinearOnboardingPage() {
  await authGuard()

  const [{ has_access }, { repositories }] = await Promise.all([
    hasLinearAccess(),
    getRepositories(),
  ])

  if (repositories.length === 0) {
    return redirect('/onboarding/repo')
  }

  return <InstallLinear hasAccess={has_access} repositories={repositories} />
}
