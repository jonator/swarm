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
} from 'lucide-react'
import { formatDistanceStrict, formatDistanceToNowStrict } from 'date-fns'
import { format, toZonedTime } from 'date-fns-tz'
import Link from 'next/link'
import { ClientOnly } from '@/components/client-only'
import { useIntervalTimer } from '@/hooks/use-interval-timer'
import type { Agent } from '@/lib/models/agents'

export function AgentHeader({
  agent,
  now,
  timeZone,
}: { agent: Agent; now: Date; timeZone: string }) {
  const { data: user } = useUser(agent.user_id)
  const isActive = agent.status === 'running'

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
    <header
      className={cn(
        'flex flex-col border-b border-border bg-background/80 px-4 py-5 sticky top-0 z-10',
        'gap-4 md:gap-3',
      )}
    >
      {/* Main info row */}
      <div className='flex flex-wrap md:flex-nowrap items-center gap-4 md:gap-6 min-w-0 w-full'>
        <div className='flex items-center gap-6 min-w-0 w-full justify-between'>
          <h1 className='text-2xl font-bold truncate' title={agent.name}>
            {agent.name}
          </h1>
          <div className='flex items-center gap-3 shrink-0'>
            {/* Status badge */}
            <StatusBadge status={agent.status} />
            {/* Type badge */}
            <TypeBadge type={agent.type} />
            {/* User */}
            {user && (
              <span className='inline-flex items-center gap-2 text-xs ml-2'>
                <Avatar className='h-5 w-5'>
                  <AvatarImage src={user.avatar_url} alt={user.username} />
                  <AvatarFallback>
                    {user.username.charAt(0).toUpperCase()}
                  </AvatarFallback>
                </Avatar>
                {user.username}
              </span>
            )}
          </div>
        </div>
      </div>
      {/* Meta row */}
      <div className='flex flex-wrap items-center gap-4 text-xs text-muted-foreground w-full mt-1'>
        <ClientOnly>
          <span
            className='inline-flex items-center gap-2'
            title={format(createdAtZoned, 'PPpp', { timeZone })}
          >
            <Calendar className='h-4 w-4 text-muted-foreground' aria-hidden />
            Created {createdAgo}
          </span>
        </ClientOnly>
        {durationLabel && (
          <ClientOnly>
            <span
              className='inline-flex items-center gap-2'
              title={durationTitle}
            >
              <Clock className='h-4 w-4 text-muted-foreground' aria-hidden />
              {durationLabel}
            </span>
          </ClientOnly>
        )}
        {agent.external_ids?.github_pr_id && (
          <Link
            href={`https://github.com/pr/${agent.external_ids.github_pr_id}`}
            target='_blank'
            rel='noopener noreferrer'
            className='inline-flex items-center gap-2 text-primary hover:text-primary/80 hover:underline'
            aria-label='View GitHub PR'
          >
            <Github className='h-4 w-4 text-muted-foreground' /> PR #
            {agent.external_ids.github_pr_id}
            <ExternalLink className='ml-0.5 h-3 w-3' />
          </Link>
        )}
        {agent.external_ids?.linear_issue_url && (
          <Link
            href={agent.external_ids.linear_issue_url}
            target='_blank'
            rel='noopener noreferrer'
            className='inline-flex items-center gap-2 text-primary hover:text-primary/80 hover:underline'
            aria-label='View Linear Issue'
          >
            <LinearLogo className='h-4 w-4' />
            {agent.external_ids.linear_issue_identifier ||
              agent.external_ids.linear_issue_id}
            <ExternalLink className='ml-0.5 h-3 w-3' />
          </Link>
        )}
        {agent.external_ids?.slack_thread_id && (
          <Link
            href={`https://slack.com/app_redirect?channel=${agent.external_ids.slack_thread_id}`}
            target='_blank'
            rel='noopener noreferrer'
            className='inline-flex items-center gap-2 text-primary hover:text-primary/80 hover:underline'
            aria-label='View Slack Thread'
          >
            <MessageSquare className='h-4 w-4 text-muted-foreground' /> Slack
            Thread
            <ExternalLink className='ml-0.5 h-3 w-3' />
          </Link>
        )}
      </div>
      {/* Context/description row */}
      {agent.context && (
        <div
          className='text-xs text-muted-foreground mt-3 line-clamp-2 w-full'
          title={agent.context}
        >
          {agent.context}
        </div>
      )}
    </header>
  )
}
