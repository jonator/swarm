import { DateTime } from 'luxon'
import type {
  AgentSource,
  AgentStatus,
  AgentType,
  ResponseAgent,
} from '../services/agents'

export type Agent = {
  id: number
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
  user_id: number
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
