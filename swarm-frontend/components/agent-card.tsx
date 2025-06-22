'use client'
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
} from './ui/card'
import type { Agent } from '@/lib/models/agents'
import {
  CheckCircle,
  Play,
  Clock,
  XCircle,
  Search,
  Code,
  FileText,
  Github,
  MessageSquare,
  User as UserIcon,
  GitBranch,
  Calendar,
  ExternalLink,
} from 'lucide-react'
import { cn } from '@/lib/utils/shadcn'
import Link from 'next/link'
import { DateTime } from 'luxon'
import Image from 'next/image'
import { useTheme } from 'next-themes'
import { useState, useEffect } from 'react'

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

const LinearLogo = ({ className }: { className?: string }) => {
  const [mounted, setMounted] = useState(false)
  const { resolvedTheme } = useTheme()

  useEffect(() => {
    setMounted(true)
  }, [])

  const logoSrc = mounted
    ? resolvedTheme === 'dark'
      ? '/linear-light-logo.svg'
      : '/linear-dark-logo.svg'
    : '/linear-dark-logo.svg'

  return (
    <Image
      src={logoSrc}
      alt='Linear'
      className={className}
      width={16}
      height={16}
    />
  )
}

const sourceMap = {
  github: { label: 'GitHub', icon: Github },
  linear: { label: 'Linear', icon: null },
  slack: { label: 'Slack', icon: MessageSquare },
  manual: { label: 'Manual', icon: UserIcon },
}

export function AgentCard({ agent }: { agent: Agent }) {
  const StatusIcon = statusMap[agent.status]?.icon
  const TypeIcon = typeMap[agent.type]?.icon
  const SourceIcon = sourceMap[agent.source]?.icon
  const repoLabel = agent.repository_id ? `Repo #${agent.repository_id}` : ''
  const userLabel = agent.user_id ? `User #${agent.user_id}` : ''
  const startedAgo = agent.started_at ? agent.started_at.toRelative() : ''
  const isActive = agent.status === 'running' || agent.status === 'pending'
  const durationLabel = isActive
    ? agent.started_at
      ? `Running for ${DateTime.now().diff(agent.started_at).toHuman({ listStyle: 'long' })}`
      : ''
    : agent.completed_at && agent.started_at
      ? `Completed in ${agent.completed_at.diff(agent.started_at).toHuman({ listStyle: 'long' })}`
      : null

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
          {repoLabel && (
            <span className='inline-flex items-center gap-1'>
              <GitBranch
                className='h-4 w-4 text-muted-foreground'
                aria-hidden
              />
              {repoLabel}
            </span>
          )}
          {userLabel && (
            <span className='inline-flex items-center gap-1'>
              <UserIcon className='h-4 w-4 text-muted-foreground' aria-hidden />
              {userLabel}
            </span>
          )}
          {startedAgo && (
            <span className='inline-flex items-center gap-1'>
              <Calendar className='h-4 w-4 text-muted-foreground' aria-hidden />
              {startedAgo}
            </span>
          )}
          {durationLabel && (
            <span className='inline-flex items-center gap-1'>
              <Clock className='h-4 w-4 text-muted-foreground' aria-hidden />
              {durationLabel}
            </span>
          )}
          <span className='inline-flex items-center gap-1'>
            {SourceIcon && (
              <SourceIcon
                className='h-4 w-4 text-muted-foreground'
                aria-hidden
              />
            )}
            {sourceMap[agent.source]?.label}
          </span>
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
