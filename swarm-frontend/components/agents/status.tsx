'use client'

import {
  CheckCircle,
  Clock,
  FileText,
  Code,
  Play,
  Search,
  XCircle,
  type LucideProps,
} from 'lucide-react'
import type { AgentStatus, AgentType } from '@/lib/services/agents'
import type { ForwardRefExoticComponent, RefAttributes } from 'react'
import { cn } from '@/lib/utils/shadcn'
import { useAgent } from '@/lib/queries/hooks/agents'

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
  const StatusIcon = agent ? statusMap[agent.status].icon : undefined

  return (
    <div className='flex items-center gap-1'>
      {StatusIcon && <StatusIcon className='h-4 w-4' aria-hidden />}
      <span className='text-foreground text-sm font-medium'>{agent?.name}</span>
    </div>
  )
}
