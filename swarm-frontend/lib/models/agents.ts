import { utc } from '@date-fns/utc'
import { parseISO } from 'date-fns'
import type {
  AgentSource,
  AgentStatus,
  AgentType,
  ResponseAgent,
} from '../services/agents'

export type Agent = {
  id: string
  name: string
  description: string
  context: string
  status: AgentStatus
  source: AgentSource
  type: AgentType
  external_ids: Record<string, string>
  started_at?: Date
  completed_at?: Date
  oban_job_id?: string
  repository_id: number
  project_id?: number
  user_id: number
  created_at: Date
  updated_at: Date
}

export function parseAgent(agent: ResponseAgent): Agent {
  return {
    id: agent.id,
    name: agent.name,
    description: agent.description,
    context: agent.context,
    status: agent.status,
    source: agent.source,
    type: agent.type,
    external_ids: agent.external_ids,
    started_at: agent.started_at
      ? parseISO(agent.started_at, { in: utc })
      : undefined,
    completed_at: agent.completed_at
      ? parseISO(agent.completed_at, { in: utc })
      : undefined,
    oban_job_id: agent.oban_job_id,
    repository_id: agent.repository_id,
    project_id: agent.project_id,
    user_id: agent.user_id,
    created_at: parseISO(agent.created_at, { in: utc }),
    updated_at: parseISO(agent.updated_at, { in: utc }),
  }
}
