import { apiClientWithAuth } from '@/lib/client/authed'

interface GetUserResponse {
  id: string
  email: string
}

export const getUser = async () =>
  apiClientWithAuth.get('users').json<GetUserResponse>()
