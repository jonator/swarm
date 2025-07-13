'use server'

import { redirect } from 'next/navigation'
import { authGuard } from '@/lib/client/authed'
import { getInstallations } from '@/lib/services/github'
import { getRepositories } from '@/lib/services/repositories'

/**
 * Routes entry into app, whether onboarding or the default
 * user or organization dashboard.
 */
export async function routeEntry() {
  await authGuard()

  const { repositories } = await getRepositories()

  if (repositories.length === 0) {
    const { total_count } = await getInstallations()

    if (total_count === 0) {
      redirect('/onboarding/github')
    }

    redirect('/onboarding/repo')
  }

  redirect(`/${repositories[0].owner}`)
}
