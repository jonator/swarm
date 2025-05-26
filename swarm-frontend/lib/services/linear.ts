'use server'

import { apiClientWithAuth } from '@/lib/client/authed'

export async function submitLinearAuth(code: string) {
  return apiClientWithAuth.post('users/auth/linear', {
    searchParams: { code },
  })
}

export async function hasLinearAccess() {
  return apiClientWithAuth
    .get('users/auth/linear')
    .json<{ has_access: boolean }>()
}
