'use client'

import { useAgent } from '@/lib/queries/hooks/agents'
import { AgentCard } from './card'

export function AgentDisplay({
  id,
  now,
  timeZone,
}: {
  id: string
  now: Date
  timeZone: string
}) {
  const { data: agent, isLoading, error } = useAgent(id)

  if (isLoading) {
    return (
      <div className='text-center text-muted-foreground py-8'>
        Loading agent...
      </div>
    )
  }
  if (error) {
    return (
      <div className='text-center text-red-500 py-8'>Error loading agent.</div>
    )
  }
  if (!agent) {
    return (
      <div className='text-center text-muted-foreground py-8'>
        Agent not found.
      </div>
    )
  }

  return <AgentCard agent={agent} now={now} timeZone={timeZone} />
}
