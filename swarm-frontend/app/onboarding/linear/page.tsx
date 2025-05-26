import { routeEntry } from '@/actions/routing'
import { InstallLinear } from '@/components/onboarding/linear'
import { authGuard } from '@/lib/client/authed'
import { hasLinearAccess } from '@/lib/services/linear'

export default async function LinearOnboardingPage() {
  await authGuard()

  const { has_access } = await hasLinearAccess()

  if (has_access) {
    routeEntry()
  }

  return <InstallLinear />
}
