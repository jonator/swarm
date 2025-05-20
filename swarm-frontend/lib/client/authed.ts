import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import { apiClient } from '.'

export const apiClientWithAuth = apiClient.extend({
  hooks: {
    beforeRequest: [
      async (request: Request) => {
        const token = await authGuard()

        // Clone request to avoid mutation issues
        const modifiedRequest = new Request(request)

        // Set Authorization header with Bearer token
        modifiedRequest.headers.set('Authorization', `Bearer ${token}`)

        return modifiedRequest
      },
    ],
    afterResponse: [
      async (_input, _options, response) => {
        if (response.status === 401) {
          redirect('/login')
        }
      },
    ],
  },
})

/**
 * Checks if user is authenticated and returns token from cookies if authenticated.
 * Otherwise, redirects to login page.
 */
export async function authGuard({
  redirect: redirectProp = true,
}: {
  /** Redirect to login page if not authenticated. Default: `true`. */
  redirect?: boolean
} = {}) {
  const cookieStore = await cookies()
  const token = cookieStore.get('access_token')

  if (!token && redirectProp) {
    redirect('/login')
  }

  return token?.value
}

export async function setAuth(token: string) {
  const cookieStore = await cookies()
  cookieStore.set('access_token', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    // Same as JWT token expiration
    maxAge: 60 * 60 * 24 * 7, // 7 days in seconds
  })
}
