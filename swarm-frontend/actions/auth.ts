'use server'

import { setAuth } from '@/lib/client/authed'
import { submitGithubAuth } from '@/lib/services/auth'

export async function submitGithubAuthCode(code: string) {
  const { token } = await submitGithubAuth(code)
  await setAuth(token)
}
