import { authGuard } from '@/lib/client/authed'
import { redirect } from 'next/navigation'

export default async function OnboardingPage() {
  await authGuard()
  redirect('onboarding/github')
}
