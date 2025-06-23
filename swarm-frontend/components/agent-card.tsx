'use client'

import { LinearLogo } from '@/components/linear-logo'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import type { Agent } from '@/lib/models/agents'
import { useRepository } from '@/lib/queries/hooks/repositories'
import { useUser } from '@/lib/queries/hooks/users'
import { cn } from '@/lib/utils/shadcn'
import {
  BookIcon,
  Calendar,
  CheckCircle,
  Clock,
  Code,
  ExternalLink,
  FileText,
  Github,
  MessageSquare,
  Play,
  Search,
  XCircle,
} from 'lucide-react'
import {
  format,
  formatDistanceStrict,
  formatDistanceToNowStrict,
} from 'date-fns'
import Link from 'next/link'

const statusMap = {
  completed: {
    label: 'Completed',
    color: 'bg-muted text-muted-foreground border border-border',
    icon: CheckCircle,
  },
  running: {
    label: 'Running',
    color: 'bg-accent text-accent-foreground border border-border',
    icon: Play,
  },
  pending: {
    label: 'Pending',
    color: 'bg-secondary text-secondary-foreground border border-border',
    icon: Clock,
  },
  failed: {
    label: 'Failed',
    color: 'bg-destructive/10 text-destructive border border-destructive/20',
    icon: XCircle,
  },
}

const typeMap = {
  researcher: {
    label: 'Researcher',
    color: 'bg-card text-card-foreground border border-border',
    icon: Search,
  },
  coder: {
    label: 'Coder',
    color: 'bg-muted text-muted-foreground border border-border',
    icon: Code,
  },
  code_reviewer: {
    label: 'Code Reviewer',
    color: 'bg-secondary text-secondary-foreground border border-border',
    icon: FileText,
  },
}

export function AgentCard({ agent, now }: { agent: Agent; now: Date }) {
  const { data: user } = useUser(agent.user_id)
  const { data: repository } = useRepository(agent.repository_id)

  const StatusIcon = statusMap[agent.status]?.icon
  const TypeIcon = typeMap[agent.type]?.icon
  const startedAgo = agent.started_at
    ? formatDistanceToNowStrict(agent.started_at, { addSuffix: true })
    : ''
  const isActive = agent.status === 'running' || agent.status === 'pending'
  const durationLabel = isActive
    ? agent.started_at
      ? `Running for ${formatDistanceStrict(now, agent.started_at)}`
      : ''
    : agent.completed_at && agent.started_at
      ? `Completed in ${formatDistanceStrict(
          agent.completed_at,
          agent.started_at,
        )}`
      : null

  let durationTitle = ''
  if (isActive && agent.started_at) {
    durationTitle = `Started at: ${format(agent.started_at, 'PPpp')}`
  } else if (!isActive && agent.started_at && agent.completed_at) {
    durationTitle = `Started: ${format(
      agent.started_at,
      'PPpp',
    )}\nCompleted: ${format(agent.completed_at, 'PPpp')}`
  }

  return (
    <Card
      key={agent.id}
      className='border-border/50 shadow-sm transition-shadow duration-200 hover:shadow-md'
    >
      <CardHeader className='flex flex-row items-center gap-4 pb-2'>
        <span
          className={cn(
            'inline-flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs font-medium',
            statusMap[agent.status]?.color,
          )}
          title={statusMap[agent.status]?.label}
        >
          {StatusIcon && <StatusIcon className='h-4 w-4' aria-hidden />}
          {statusMap[agent.status]?.label}
        </span>
        <CardTitle className='flex-1 truncate text-lg font-bold'>
          {agent.name}
        </CardTitle>
        <span
          className={cn(
            'inline-flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs font-medium',
            typeMap[agent.type]?.color,
          )}
          title={typeMap[agent.type]?.label}
        >
          {TypeIcon && <TypeIcon className='h-4 w-4' aria-hidden />}
          {typeMap[agent.type]?.label}
        </span>
      </CardHeader>
      <CardContent className='flex flex-col gap-2 pt-0'>
        <CardDescription className='line-clamp-2' title={agent.context}>
          {agent.context}
        </CardDescription>
        <div className='mt-1 flex flex-wrap items-center gap-3 text-xs text-muted-foreground'>
          {repository && (
            <span className='inline-flex items-center gap-1'>
              <BookIcon className='h-4 w-4 text-muted-foreground' aria-hidden />
              {repository ? (
                <>
                  <span className='text-muted-foreground'>
                    {repository.owner}
                  </span>
                  <span> / </span>
                  <span className='font-bold'>{repository.name}</span>
                </>
              ) : (
                ''
              )}
            </span>
          )}
          {user && (
            <span className='inline-flex items-center gap-1.5'>
              <Avatar className='h-4 w-4'>
                <AvatarImage src={user.avatar_url} alt={user.username} />
                <AvatarFallback>
                  {user.username.charAt(0).toUpperCase()}
                </AvatarFallback>
              </Avatar>
              {user.username}
            </span>
          )}
          {startedAgo && agent.started_at && (
            <span
              className='inline-flex items-center gap-1'
              title={format(agent.started_at, 'PPpp')}
            >
              <Calendar className='h-4 w-4 text-muted-foreground' aria-hidden />
              {startedAgo}
            </span>
          )}
          {durationLabel && (
            <span
              className='inline-flex items-center gap-1'
              title={durationTitle}
            >
              <Clock className='h-4 w-4 text-muted-foreground' aria-hidden />
              {durationLabel}
            </span>
          )}
          {/* External Links */}
          {agent.external_ids?.github_pr_id && (
            <Link
              href={`https://github.com/pr/${agent.external_ids.github_pr_id}`}
              target='_blank'
              rel='noopener noreferrer'
              className='inline-flex items-center gap-1 text-primary transition-colors duration-150 hover:text-primary/80 hover:underline focus:outline-none'
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
              className='inline-flex items-center gap-1 text-primary transition-colors duration-150 hover:text-primary/80 hover:underline focus:outline-none'
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
              className='inline-flex items-center gap-1 text-primary transition-colors duration-150 hover:text-primary/80 hover:underline focus:outline-none'
              aria-label='View Slack Thread'
            >
              <MessageSquare className='h-4 w-4 text-muted-foreground' /> Slack
              Thread
              <ExternalLink className='ml-0.5 h-3 w-3' />
            </Link>
          )}
        </div>
      </CardContent>
    </Card>
  )
}
