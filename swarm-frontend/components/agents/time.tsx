'use client'

import { formatDistanceStrict } from 'date-fns'
import { format, toZonedTime } from 'date-fns-tz'
import { Calendar, Clock } from 'lucide-react'
import { ClientOnly } from '@/components/client-only'
import { useIntervalTimer } from '@/hooks/use-interval-timer'

export function AgentCreatedTime({
  createdAt,
  timeZone,
  now,
  className = '',
}: {
  createdAt?: Date | string
  timeZone: string
  now: Date
  className?: string
}) {
  // Update every second to keep "time ago" current
  const currentNow = useIntervalTimer(now, true, 1000)

  if (!createdAt) return null

  const zoned = toZonedTime(createdAt, timeZone)
  const createdAgo = formatDistanceStrict(zoned, currentNow, {
    addSuffix: true,
    roundingMethod: 'floor',
  })

  return (
    <ClientOnly>
      <span
        className={`inline-flex items-center gap-1 ${className}`}
        title={format(zoned, 'PPpp', { timeZone })}
      >
        <Calendar className='h-4 w-4 text-muted-foreground' aria-hidden />
        Created {createdAgo}
      </span>
    </ClientOnly>
  )
}

export function AgentDuration({
  isActive,
  startedAt,
  completedAt,
  now,
  timeZone,
  className = '',
}: {
  isActive: boolean
  startedAt?: Date | string
  completedAt?: Date | string
  now: Date
  timeZone: string
  className?: string
}) {
  // Update every second when active, or just once when completed
  const currentNow = useIntervalTimer(now, isActive, 1000)

  if (!startedAt) return null

  const startedAtZoned = toZonedTime(startedAt, timeZone)
  const completedAtZoned = completedAt
    ? toZonedTime(completedAt, timeZone)
    : undefined

  let durationLabel: string | null = null
  let durationTitle = ''

  if (isActive) {
    durationLabel = `Running for ${formatDistanceStrict(currentNow, startedAt)}`
    durationTitle = `Started at: ${format(startedAtZoned, 'PPpp', { timeZone })}`
  } else if (completedAt && startedAt) {
    durationLabel = `Completed in ${formatDistanceStrict(completedAt, startedAt)}`
    durationTitle = `Started: ${format(startedAtZoned, 'PPpp', { timeZone })}\nCompleted: ${format(completedAtZoned!, 'PPpp', { timeZone })}`
  }

  if (!durationLabel) return null

  return (
    <ClientOnly>
      <span
        className={`inline-flex items-center gap-1 ${className}`}
        title={durationTitle}
      >
        <Clock className='h-4 w-4 text-muted-foreground' aria-hidden />
        {durationLabel}
      </span>
    </ClientOnly>
  )
}
