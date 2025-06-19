'use client'
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
} from './ui/card'
import { useAgents } from '@/lib/queries/hooks/agents'
import type { GetAgentsParams } from '@/lib/services/agents'
import {
  CheckCircle,
  Play,
  Clock,
  XCircle,
  Search,
  Code,
  FileText,
  Github,
  Zap,
  MessageSquare,
  User as UserIcon,
  GitBranch,
  Calendar,
  ExternalLink,
} from 'lucide-react'
import { cn } from '@/lib/utils/shadcn'
import Link from 'next/link'
import { DateTime } from 'luxon'

const statusMap = {
  completed: {
    label: 'Completed',
    color: 'bg-green-600 text-green-100',
    icon: CheckCircle,
  },
  running: {
    label: 'Running',
    color: 'bg-blue-600 text-blue-100',
    icon: Play,
  },
  pending: {
    label: 'Pending',
    color: 'bg-yellow-600 text-yellow-100',
    icon: Clock,
  },
  failed: {
    label: 'Failed',
    color: 'bg-red-600 text-red-100',
    icon: XCircle,
  },
}

const typeMap = {
  researcher: {
    label: 'Researcher',
    color: 'bg-purple-700 text-purple-100',
    icon: Search,
  },
  coder: {
    label: 'Coder',
    color: 'bg-blue-700 text-blue-100',
    icon: Code,
  },
  code_reviewer: {
    label: 'Code Reviewer',
    color: 'bg-orange-600 text-orange-100',
    icon: FileText,
  },
}

const sourceMap = {
  github: { label: 'GitHub', icon: Github },
  linear: { label: 'Linear', icon: Zap },
  slack: { label: 'Slack', icon: MessageSquare },
  manual: { label: 'Manual', icon: UserIcon },
}

export function AgentsList({ params }: { params: GetAgentsParams }) {
  const { data: agents = [], isLoading, error } = useAgents({ ...params })

  console.log(DateTime)

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
      {agents.map((agent) => {
        const StatusIcon = statusMap[agent.status]?.icon
        const TypeIcon = typeMap[agent.type]?.icon
        const SourceIcon = sourceMap[agent.source]?.icon
        const repoLabel = agent.repository_id
          ? `Repo #${agent.repository_id}`
          : ''
        const userLabel = agent.user_id ? `User #${agent.user_id}` : ''
        const startedAgo = agent.started_at ? agent.started_at.toRelative() : ''
        const isActive =
          agent.status === 'running' || agent.status === 'pending'
        const durationLabel = isActive
          ? agent.started_at
            ? `Running for ${DateTime.now().diff(agent.started_at).toHuman({ listStyle: 'long' })}`
            : ''
          : agent.completed_at && agent.started_at
            ? `Completed in ${agent.completed_at.diff(agent.started_at).toHuman({ listStyle: 'long' })}`
            : null

        return (
          <Card key={agent.id}>
            <CardHeader className='flex flex-row items-center gap-4 pb-2'>
              <span
                className={cn(
                  'inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-semibold',
                  statusMap[agent.status]?.color,
                )}
                title={statusMap[agent.status]?.label}
              >
                {StatusIcon && <StatusIcon className='w-4 h-4' aria-hidden />}
                {statusMap[agent.status]?.label}
              </span>
              <CardTitle className='flex-1 text-lg font-bold truncate'>
                {agent.name}
              </CardTitle>
              <span
                className={cn(
                  'inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold',
                  typeMap[agent.type]?.color,
                )}
                title={typeMap[agent.type]?.label}
              >
                {TypeIcon && <TypeIcon className='w-4 h-4' aria-hidden />}
                {typeMap[agent.type]?.label}
              </span>
            </CardHeader>
            <CardContent className='flex flex-col gap-2 pt-0'>
              <CardDescription className='line-clamp-2' title={agent.context}>
                {agent.context}
              </CardDescription>
              <div className='flex flex-wrap items-center gap-3 text-xs text-muted-foreground mt-1'>
                {repoLabel && (
                  <span className='inline-flex items-center gap-1'>
                    <GitBranch className='w-4 h-4' aria-hidden />
                    {repoLabel}
                  </span>
                )}
                {userLabel && (
                  <span className='inline-flex items-center gap-1'>
                    <UserIcon className='w-4 h-4' aria-hidden />
                    {userLabel}
                  </span>
                )}
                {startedAgo && (
                  <span className='inline-flex items-center gap-1'>
                    <Calendar className='w-4 h-4' aria-hidden />
                    {startedAgo}
                  </span>
                )}
                {durationLabel && (
                  <span className='inline-flex items-center gap-1'>
                    <Clock className='w-4 h-4' aria-hidden />
                    {durationLabel}
                  </span>
                )}
                <span className='inline-flex items-center gap-1'>
                  {SourceIcon && <SourceIcon className='w-4 h-4' aria-hidden />}
                  {sourceMap[agent.source]?.label}
                </span>
                {/* External Links */}
                {agent.external_ids?.github_pr_id && (
                  <Link
                    href={`https://github.com/pr/${agent.external_ids.github_pr_id}`}
                    target='_blank'
                    rel='noopener noreferrer'
                    className='inline-flex items-center gap-1 text-blue-400 hover:underline focus:outline-none'
                    aria-label='View GitHub PR'
                  >
                    <Github className='w-4 h-4' /> PR #
                    {agent.external_ids.github_pr_id}
                    <ExternalLink className='w-3 h-3 ml-0.5' />
                  </Link>
                )}
                {agent.external_ids?.linear_issue_id && (
                  <Link
                    href={`https://linear.app/issue/${agent.external_ids.linear_issue_id}`}
                    target='_blank'
                    rel='noopener noreferrer'
                    className='inline-flex items-center gap-1 text-purple-400 hover:underline focus:outline-none'
                    aria-label='View Linear Issue'
                  >
                    <Zap className='w-4 h-4' />{' '}
                    {agent.external_ids.linear_issue_id}
                    <ExternalLink className='w-3 h-3 ml-0.5' />
                  </Link>
                )}
                {agent.external_ids?.slack_thread_id && (
                  <Link
                    href={`https://slack.com/app_redirect?channel=${agent.external_ids.slack_thread_id}`}
                    target='_blank'
                    rel='noopener noreferrer'
                    className='inline-flex items-center gap-1 text-green-400 hover:underline focus:outline-none'
                    aria-label='View Slack Thread'
                  >
                    <MessageSquare className='w-4 h-4' /> Slack Thread
                    <ExternalLink className='w-3 h-3 ml-0.5' />
                  </Link>
                )}
              </div>
            </CardContent>
          </Card>
        )
      })}
    </section>
  )
}
