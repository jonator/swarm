import type { GetAgentsParams } from '@/lib/services/agents'
import { useQuery } from '@tanstack/react-query'
import { agentsQuery } from '../keys/agents'

export function useAgents(params: GetAgentsParams) {
  return useQuery(agentsQuery(params))
}
