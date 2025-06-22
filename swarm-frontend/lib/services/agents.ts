'use server'

import { apiClientWithAuth } from '@/lib/client/authed'

export type AgentStatus = 'pending' | 'running' | 'completed' | 'failed'
export type AgentSource = 'manual' | 'linear' | 'slack' | 'github'
export type AgentType = 'researcher' | 'coder' | 'code_reviewer'

export type ResponseAgent = {
  id: string
  name: string
  context: string
  status: AgentStatus
  source: AgentSource
  type: AgentType
  external_ids: Record<string, string>
  started_at?: string
  completed_at?: string
  oban_job_id?: string
  repository_id: number
  project_id?: number
  user_id: number
  created_at: string
  updated_at: string
}

export type AgentsResponse = {
  agents: ResponseAgent[]
}

export type GetAgentsParams =
  | {
      repository_name: string
    }
  | {
      organization_name: string
    }

export async function getAgents(params: GetAgentsParams) {
  return apiClientWithAuth
    .get('agents', { searchParams: { ...params } })
    .json<AgentsResponse>()
}
