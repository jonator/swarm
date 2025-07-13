import { redirect } from 'next/navigation'
import { authGuard } from '@/lib/client/authed'

export default async function OnboardingPage() {
  await authGuard()
  redirect('onboarding/github')
}
