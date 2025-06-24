'use server'

import { apiClientWithAuth, authGuard } from '@/lib/client/authed'

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
          revalidate: 1, // 1 second
        },
      })
      .json<{ user: User }>()
  }

  const token = await authGuard()

  // Avoid caching since it's JWT token dependent
  return apiClientWithAuth
    .get('users', {
      next: {
        tags: ['users', token!.slice(0, 200)],
        revalidate: 2, // 2 seconds
      },
    })
    .json<{ user: User }>()
}
