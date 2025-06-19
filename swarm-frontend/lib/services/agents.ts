import type { ShapeStreamOptions } from '@electric-sql/client'
import { DateTime } from 'luxon'

export type AgentStatus = 'pending' | 'running' | 'completed' | 'failed'
export type AgentSource = 'manual' | 'linear' | 'slack' | 'github'
export type AgentType = 'researcher' | 'coder' | 'code_reviewer'

export type ResponseAgent = Record<string, unknown> & {
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
  user_id?: number
  created_at: string
  updated_at: string
}

export type Agent = {
  id: string
  name: string
  context: string
  status: AgentStatus
  source: AgentSource
  type: AgentType
  external_ids: Record<string, string>
  started_at?: DateTime
  completed_at?: DateTime
  oban_job_id?: string
  repository_id: number
  project_id?: number
  user_id?: number
  created_at: DateTime
  updated_at: DateTime
}

export function parseAgent(agent: ResponseAgent): Agent {
  return {
    id: agent.id,
    name: agent.name,
    context: agent.context,
    status: agent.status,
    source: agent.source,
    type: agent.type,
    external_ids: agent.external_ids,
    started_at: agent.started_at
      ? DateTime.fromISO(agent.started_at)
      : undefined,
    completed_at: agent.completed_at
      ? DateTime.fromISO(agent.completed_at)
      : undefined,
    oban_job_id: agent.oban_job_id,
    repository_id: agent.repository_id,
    project_id: agent.project_id,
    user_id: agent.user_id,
    created_at: DateTime.fromISO(agent.created_at),
    updated_at: DateTime.fromISO(agent.updated_at),
  }
}

export type GetAgentsParams =
  | {
      repository_id: string
    }
  | {
      organization_id: string
    }

export function getAgentsOptions(params: GetAgentsParams, authToken: string) {
  return {
    url: `${process.env.NEXT_PUBLIC_API_BASE_URL}/api/agents`,
    params,
    headers: {
      Authorization: `Bearer ${authToken}`,
    },
  } satisfies ShapeStreamOptions<ResponseAgent>
}
