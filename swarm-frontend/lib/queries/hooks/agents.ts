import { useQuery } from '@tanstack/react-query'
import type { GetAgentsParams } from '@/lib/services/agents'
import { agentQuery, agentsQuery } from '../keys/agents'

export const useAgents = (params: GetAgentsParams) =>
  useQuery(agentsQuery(params))

/** UUID ID */
export const useAgent = (id: string) => useQuery(agentQuery(id))
