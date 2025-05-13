import { apiClient } from '../client'

interface SubmitGithubResponse {
  token: string
}

export const submitGithubAuth = async (code: string) =>
  apiClient
    .post('auth/github', { searchParams: { code } })
    .json<SubmitGithubResponse>()
