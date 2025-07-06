'use server'

import { apiClientWithAuth } from '../client/authed'

export async function temporaryToken() {
  return apiClientWithAuth.get('auth/token').json<{ token: string }>()
}
