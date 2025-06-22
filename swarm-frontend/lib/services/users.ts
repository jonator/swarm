import { apiClientWithAuth } from '@/lib/client/authed'

export type User = {
  id: string
  email: string
  username: string
  avatar_url: string
}

export async function getUser() {
  return apiClientWithAuth.get('users').json<{ user: User }>()
}
