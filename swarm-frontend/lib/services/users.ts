import { apiClientWithAuth } from '@/lib/client/authed'

interface GetUserResponse {
  id: string
  email: string
}

export async function getUser() {
  return apiClientWithAuth.get('users').json<GetUserResponse>()
}
