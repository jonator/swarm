'use client'

import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { LinearLogo } from '@/components/linear-logo'
import { StatusBadge, TypeBadge } from './status'
import { useUser } from '@/lib/queries/hooks/users'
import { cn } from '@/lib/utils/shadcn'
import {
  Calendar,
  Clock,
  ExternalLink,
  Github,
  MessageSquare,
  ChevronDown,
  ChevronUp,
} from 'lucide-react'
import { formatDistanceStrict, formatDistanceToNowStrict } from 'date-fns'
import { format, toZonedTime } from 'date-fns-tz'
import Link from 'next/link'
import { ClientOnly } from '@/components/client-only'
import { useIntervalTimer } from '@/hooks/use-interval-timer'
import type { Agent } from '@/lib/models/agents'
import { useState } from 'react'

export function AgentHeader({
  agent,
  now,
  timeZone,
}: { agent: Agent; now: Date; timeZone: string }) {
  const { data: user } = useUser(agent.user_id)
  const isActive = agent.status === 'running'
  const [isDescriptionExpanded, setIsDescriptionExpanded] = useState(false)

  // Time helpers
  const createdAtZoned = toZonedTime(agent.created_at, timeZone)
  const createdAgo = formatDistanceToNowStrict(createdAtZoned, {
    addSuffix: true,
  })
  const startedAtZoned = agent.started_at
    ? toZonedTime(agent.started_at, timeZone)
    : undefined
  const completedAtZoned = agent.completed_at
    ? toZonedTime(agent.completed_at, timeZone)
    : undefined
  const currentNow = useIntervalTimer(now, isActive, 1000)
  let durationLabel: string | null = null
  let durationTitle = ''
  if (isActive && agent.started_at) {
    durationLabel = `Running for ${formatDistanceStrict(currentNow, agent.started_at)}`
    durationTitle = `Started at: ${format(startedAtZoned!, 'PPpp', { timeZone })}`
  } else if (agent.completed_at && agent.started_at) {
    durationLabel = `Completed in ${formatDistanceStrict(agent.completed_at, agent.started_at)}`
    durationTitle = `Started: ${format(startedAtZoned!, 'PPpp', { timeZone })}\nCompleted: ${format(completedAtZoned!, 'PPpp', { timeZone })}`
  }

  return (
    <header className='bg-card border border-border rounded-lg p-6 shadow-sm'>
      {/* Top Row - Status & Actions */}
      <div className='flex items-center justify-between mb-4'>
        <div className='flex items-center gap-2'>
          <StatusBadge status={agent.status} />
          <TypeBadge type={agent.type} />
        </div>

        {user && (
          <div className='flex items-center gap-3'>
            <Avatar
              className='w-8 h-8 rounded-full border-2 border-primary/20'
              title={user.username}
            >
              <AvatarImage src={user.avatar_url} alt={user.username} />
              <AvatarFallback>
                {user.username.charAt(0).toUpperCase()}
              </AvatarFallback>
            </Avatar>
          </div>
        )}
      </div>

      {/* Title Section */}
      <div className='space-y-2 mb-4'>
        <h1 className='text-2xl md:text-3xl font-semibold text-foreground tracking-tight'>
          {agent.name}
        </h1>
      </div>

      {/* Metadata Row */}
      <div className='flex items-center gap-4 text-xs text-muted-foreground mb-4 flex-wrap'>
        <ClientOnly>
          <div
            className='flex items-center gap-1.5'
            title={format(createdAtZoned, 'PPpp', { timeZone })}
          >
            <Calendar className='h-4 w-4' />
            Created {createdAgo}
          </div>
        </ClientOnly>

        {durationLabel && (
          <ClientOnly>
            <div className='flex items-center gap-1.5' title={durationTitle}>
              <Clock className='h-4 w-4' />
              {durationLabel}
            </div>
          </ClientOnly>
        )}

        {agent.external_ids?.github_pr_id && (
          <Link
            href={`https://github.com/pr/${agent.external_ids.github_pr_id}`}
            target='_blank'
            rel='noopener noreferrer'
            className='inline-flex items-center gap-1 px-2 py-1 bg-muted rounded text-xs font-mono hover:bg-muted/80 transition-colors duration-200'
          >
            <Github className='h-3 w-3' />
            PR #{agent.external_ids.github_pr_id}
            <ExternalLink className='h-3 w-3' />
          </Link>
        )}

        {agent.external_ids?.linear_issue_url && (
          <Link
            href={agent.external_ids.linear_issue_url}
            target='_blank'
            rel='noopener noreferrer'
            className='inline-flex items-center gap-1 px-2 py-1 bg-muted rounded text-xs font-mono hover:bg-muted/80 transition-colors duration-200'
          >
            <LinearLogo className='h-3 w-3' />
            {agent.external_ids.linear_issue_identifier ||
              agent.external_ids.linear_issue_id}
            <ExternalLink className='h-3 w-3' />
          </Link>
        )}

        {agent.external_ids?.slack_thread_id && (
          <Link
            href={`https://slack.com/app_redirect?channel=${agent.external_ids.slack_thread_id}`}
            target='_blank'
            rel='noopener noreferrer'
            className='inline-flex items-center gap-1 px-2 py-1 bg-muted rounded text-xs font-mono hover:bg-muted/80 transition-colors duration-200'
          >
            <MessageSquare className='h-3 w-3' />
            Slack Thread
            <ExternalLink className='h-3 w-3' />
          </Link>
        )}
      </div>

      {/* Description Section */}
      {agent.context && (
        <div className='space-y-2'>
          <div
            className={cn(
              'text-sm text-muted-foreground leading-relaxed',
              !isDescriptionExpanded && 'line-clamp-2',
            )}
            title={agent.context}
          >
            {agent.context}
          </div>
          {agent.context.length > 150 && (
            <button
              onClick={() => setIsDescriptionExpanded(!isDescriptionExpanded)}
              className='flex items-center gap-1 text-xs text-primary hover:text-primary/80 cursor-pointer transition-colors duration-200'
            >
              {isDescriptionExpanded ? (
                <>
                  <ChevronUp className='h-3 w-3' />
                  Show less
                </>
              ) : (
                <>
                  <ChevronDown className='h-3 w-3' />
                  Show more
                </>
              )}
            </button>
          )}
        </div>
      )}
    </header>
  )
}
