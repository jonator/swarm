'use server'

import { setAuth } from '@/lib/client/authed'
import { submitGithubAuth } from '@/lib/services/auth'
import { submitLinearAuth } from '@/lib/services/linear'
import { redirect } from 'next/navigation'

export async function submitGithubAuthCode(code: string) {
  const { token } = await submitGithubAuth(code)
  await setAuth(token)
}

export async function submitLinearAuthCode(code: string) {
  await submitLinearAuth(code)
}

export async function logout() {
  await setAuth(null)
  redirect('/')
}
