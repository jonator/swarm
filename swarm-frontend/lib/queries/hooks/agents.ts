import type { GetAgentsParams } from '@/lib/services/agents'
import { useQuery } from '@tanstack/react-query'
import { agentsQuery } from '../keys/agents'

export const useAgents = (params: GetAgentsParams) =>
  useQuery(agentsQuery(params))
