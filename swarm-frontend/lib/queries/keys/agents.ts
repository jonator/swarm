import { queryOptions } from '@tanstack/react-query'
import { getAgents, type GetAgentsParams } from '@/lib/services/agents'
import { parseAgent } from '@/lib/models/agents'

export const agentsQuery = (params: GetAgentsParams) =>
  queryOptions({
    queryKey: ['agents', 'list', params],
    queryFn: () => getAgents(params),
    refetchInterval: 1000 * 5, // 5 seconds
    select: (data) => {
      const parsedData = data.agents.map(parseAgent)
      return parsedData.sort((a, b) =>
        (a.created_at?.toMillis?.() ?? 0) < (b.created_at?.toMillis?.() ?? 0)
          ? 1
          : -1,
      )
    },
  })