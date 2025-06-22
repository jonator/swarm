import { apiClientWithAuth } from '../client/authed'

type Organization = {
  id: number
  name: string
  github_installation_id: number
}

export async function getOrganizations() {
  return apiClientWithAuth.get('organizations').json<Organization>()
}
