import { redirect } from 'next/navigation'
import { InstallGithub } from '@/components/onboarding/github'
import { authGuard } from '@/lib/client/authed'
import { getInstallations } from '@/lib/services/github'

export default async function GithubOnboardingPage() {
  await authGuard()
  const { total_count } = await getInstallations()

  if (total_count > 0) {
    redirect('repo')
  }

  return <InstallGithub />
}
