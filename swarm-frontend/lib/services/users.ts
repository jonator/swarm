'use server'

import { apiClientWithAuth } from '@/lib/client/authed'

export type User = {
  id: number
  email: string
  username: string
  avatar_url: string
}

export type GetUserParams = {
  id?: number
}

export async function getUser(params?: GetUserParams) {
  if (params?.id) {
    return apiClientWithAuth
      .get(`users/${params.id}`, {
        next: {
          revalidate: 1,
        },
      })
      .json<{ user: User }>()
  }

  // Avoid caching since it's JWT token dependent
  return apiClientWithAuth.get('users').json<{ user: User }>()
}
