import { apiClient } from '../client'

interface SubmitGithubResponse {
  token: string
}

export async function submitGithubAuth(code: string) {
  return apiClient
    .post('auth/github', { searchParams: { code } })
    .json<SubmitGithubResponse>()
}
