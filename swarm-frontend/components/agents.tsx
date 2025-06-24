'use client'
import { useAgents } from '@/lib/queries/hooks/agents'
import type { GetAgentsParams } from '@/lib/services/agents'
import { AgentCard } from './agent-card'

export function AgentsList(
  props: GetAgentsParams & { now: Date; timeZone: string },
) {
  const { now, timeZone, ...agentParams } = props
  const { data: agents = [], isLoading, error } = useAgents(agentParams)

  if (isLoading) {
    return (
      <div className='text-center text-muted-foreground py-8'>
        Loading agents...
      </div>
    )
  }
  if (error) {
    return (
      <div className='text-center text-red-500 py-8'>Error loading agents.</div>
    )
  }
  if (!agents.length) {
    return (
      <div className='text-center text-muted-foreground py-8'>
        No agents found.
      </div>
    )
  }

  return (
    <section className='flex flex-col gap-4 w-full py-8 px-2 md:px-0'>
      {agents.map((agent) => (
        <AgentCard agent={agent} key={agent.id} now={now} timeZone={timeZone} />
      ))}
    </section>
  )
}
