import { parseAgent } from '@/lib/models/agents'
import { type GetAgentsParams, getAgents } from '@/lib/services/agents'
import { queryOptions } from '@tanstack/react-query'

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
    refetchInterval: 1000 * 5, // 5 seconds
    select: (data) => {
      const parsedData = data.agents.map(parseAgent)
      return parsedData.sort(
        (a, b) => b.created_at.getTime() - a.created_at.getTime(),
      )
    },
  })
