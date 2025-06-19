import { useShape } from '@electric-sql/react'
import { useTemporaryToken } from './auth'
import {
  type ResponseAgent,
  type GetAgentsParams,
  getAgentsOptions,
  parseAgent,
} from '@/lib/services/agents'
import { useMemo } from 'react'

export function useAgents(params: GetAgentsParams) {
  const { data: temporaryToken } = useTemporaryToken()
  const result = useShape<ResponseAgent>(
    getAgentsOptions(params, temporaryToken!.token),
  )

  // Parse and sort data in useMemo
  const sortedData = useMemo(() => {
    if (!result.data) return []
    const parsedData = result.data.map(parseAgent)
    return parsedData.sort((a, b) =>
      (a.created_at?.toMillis?.() ?? 0) < (b.created_at?.toMillis?.() ?? 0)
        ? 1
        : -1,
    )
  }, [result.data])

  return { ...result, data: sortedData }
}
