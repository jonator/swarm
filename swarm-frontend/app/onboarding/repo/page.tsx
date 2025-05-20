import { ChooseRepo } from '@/components/onboarding/repo'
import { authGuard } from '@/lib/client/authed'
import { getRepositories } from '@/lib/services/github'

export default async function RepoOnboardingPage() {
  await authGuard()
  const repositories = await getRepositories()

  return <ChooseRepo repositories={repositories} />
}
