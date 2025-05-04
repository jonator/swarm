import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import { apiClient } from '.'

export const apiClientWithAuth = apiClient.extend({
  hooks: {
    beforeRequest: [
      async (request: Request) => {
        const cookieStore = await cookies()
        const token = cookieStore.get('access_token')

        if (!token) {
          redirect('/login')
        }

        // Clone request to avoid mutation issues
        const modifiedRequest = new Request(request)

        // Set Authorization header with Bearer token
        modifiedRequest.headers.set('Authorization', `Bearer ${token?.value}`)

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
