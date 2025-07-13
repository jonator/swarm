import { queryOptions } from '@tanstack/react-query'
import { parseAgent } from '@/lib/models/agents'
import {
  type GetAgentsParams,
  getAgent,
  getAgents,
} from '@/lib/services/agents'

export const agentsQuery = (params: GetAgentsParams) =>
  queryOptions({
    queryKey:
      'organization_name' in params
        ? ['agents', 'organization', params.organization_name, 'list']
        : 'repository_name' in params
          ? ['agents', 'repository', params.repository_name, 'list']
          : (() => {
              throw new Error('Invalid params')
            })(),
    queryFn: () => getAgents(params),
    staleTime: 1000 * 5, // 5 seconds
    refetchInterval: 1000 * 5, // 5 seconds
    select: (data) => {
      const parsedData = data.agents.map(parseAgent)
      return parsedData.sort(
        (a, b) => b.created_at.getTime() - a.created_at.getTime(),
      )
    },
  })

/** UUID ID */
export const agentQuery = (id: string) =>
  queryOptions({
    queryKey: ['agents', 'agent', id],
    queryFn: () => getAgent(id),
    staleTime: 1000 * 5, // 5 seconds
    refetchInterval: 1000 * 5, // 5 seconds
    select: (data) => parseAgent(data.agent),
  })
