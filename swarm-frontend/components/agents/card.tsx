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
import { BookIcon, ExternalLink, Github, MessageSquare } from 'lucide-react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { StatusBadge, TypeBadge } from './status'
import { AgentCreatedTime, AgentDuration } from './time'

type AgentCardHeaderProps = {
  agent: Agent
}

function AgentCardHeader({ agent }: AgentCardHeaderProps) {
  return (
    <CardHeader className='flex flex-row items-center gap-4 pb-2'>
      <StatusBadge status={agent.status} />
      <CardTitle className='flex-1 truncate text-lg font-bold'>
        {agent.name}
      </CardTitle>
      <TypeBadge type={agent.type} />
    </CardHeader>
  )
}

export function AgentCard({
  agent,
  now,
  timeZone,
}: {
  agent: Agent
  now: Date
  timeZone: string
}) {
  const { data: user } = useUser(agent.user_id)
  const { data: repository } = useRepository(agent.repository_id)
  const router = useRouter()
  const agentPath = repository
    ? `/${repository.owner}/${repository.name}/agents/${agent.id}`
    : undefined
  const isActive = agent.status === 'running'

  // Handler for card click
  const handleCardClick = (e: React.MouseEvent) => {
    if (!agentPath) return
    // Prevent navigation if clicking on a link or button inside the card
    const target = e.target as HTMLElement
    if (target.closest('a,button,[role="button"],[tabindex]') || !repository) {
      return
    }
    router.push(agentPath)
  }

  return (
    <Card
      key={agent.id}
      className={cn(
        'border-border/50 shadow-sm transition-shadow duration-200 hover:shadow-md hover:bg-accent',
        repository && 'cursor-pointer',
      )}
      onClick={handleCardClick}
      onBlur={() => {
        if (!agentPath) return
        router.prefetch(agentPath)
      }}
    >
      {repository ? (
        <Link
          href={`/${repository.owner}/${repository.name}/agents/${agent.id}`}
          className='no-underline hover:no-underline focus:no-underline'
        >
          <AgentCardHeader agent={agent} />
        </Link>
      ) : (
        <AgentCardHeader agent={agent} />
      )}
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
          {/* Created Time */}
          <AgentCreatedTime
            createdAt={agent.created_at}
            timeZone={timeZone}
            now={now}
          />
          {/* Duration */}
          <AgentDuration
            isActive={isActive}
            startedAt={agent.started_at}
            completedAt={agent.completed_at}
            now={now}
            timeZone={timeZone}
          />
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
