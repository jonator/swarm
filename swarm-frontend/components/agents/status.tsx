'use client'

import { useAgent } from '@/lib/queries/hooks/agents'
import type { AgentStatus, AgentType } from '@/lib/services/agents'
import { cn } from '@/lib/utils/shadcn'
import {
  CheckCircle,
  Clock,
  Code,
  FileText,
  type LucideProps,
  Play,
  Search,
  XCircle,
} from 'lucide-react'
import type { ForwardRefExoticComponent, RefAttributes } from 'react'

export const statusMap: Record<
  AgentStatus,
  {
    label: string
    color: string
    icon: ForwardRefExoticComponent<
      Omit<LucideProps, 'ref'> & RefAttributes<SVGSVGElement>
    >
  }
> = {
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

export const typeMap: Record<
  AgentType,
  {
    label: string
    color: string
    icon: ForwardRefExoticComponent<
      Omit<LucideProps, 'ref'> & RefAttributes<SVGSVGElement>
    >
  }
> = {
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

// Badge for agent type and status (for use in breadcrumbs, etc.)
type AgentTypeStatusBadgeProps = {
  type: AgentType
  status: AgentStatus
}

export function AgentTypeStatusBadge({
  type,
  status,
}: AgentTypeStatusBadgeProps) {
  const StatusIcon = statusMap[status].icon
  return (
    <div
      className={cn(
        'inline-flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs font-medium',
        typeMap[type].color,
      )}
    >
      {StatusIcon && <StatusIcon className='h-4 w-4' aria-hidden />}
      {typeMap[type].label}
    </div>
  )
}

export function AgentBreadcrumb({ id }: { id: string }) {
  const { data: agent } = useAgent(id)

  if (!agent) return null

  const StatusIcon = statusMap[agent.status].icon

  return (
    <div className='flex items-center gap-1.5'>
      <StatusIcon className='h-4 w-4' aria-hidden />
      <span className='text-foreground text-sm font-medium'>{agent.name}</span>
    </div>
  )
}

// Status badge for agent status
export function StatusBadge({
  status,
  className,
}: { status: AgentStatus; className?: string }) {
  const StatusIcon = statusMap[status].icon
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs font-medium',
        statusMap[status].color,
        className,
      )}
      title={statusMap[status].label}
    >
      {StatusIcon && <StatusIcon className='h-4 w-4' aria-hidden />}{' '}
      {statusMap[status].label}
    </span>
  )
}

// Type badge for agent type
export function TypeBadge({
  type,
  className,
}: { type: AgentType; className?: string }) {
  const TypeIcon = typeMap[type].icon
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs font-medium',
        typeMap[type].color,
        className,
      )}
      title={typeMap[type].label}
    >
      {TypeIcon && <TypeIcon className='h-4 w-4' aria-hidden />}{' '}
      {typeMap[type].label}
    </span>
  )
}
