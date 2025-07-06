'use client'

import { useState } from 'react'
import { cn } from '@/lib/utils/shadcn'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import type { ToolCall, ToolResult } from '@/hooks/use-agent-channel'
import {
  FolderOpen,
  Search,
  Plus,
  Upload,
  RotateCcw,
  Eye,
  Edit3,
  Activity,
  GitPullRequest,
  MessageCircle,
  Check,
  Save,
  CheckCircle,
  AlertCircle,
  RefreshCw,
  Clock,
  Bot,
  ChevronDown,
  ChevronUp,
  Copy,
  type LucideIcon,
} from 'lucide-react'

export type ToolCategory = 'git' | 'github' | 'agent'
export type ToolStatus = 'success' | 'error' | 'pending' | 'running'

export interface ToolConfig {
  name: string
  displayName: string
  description: string
  icon: LucideIcon
  category: ToolCategory
}

// Tool configurations mapped by tool name
const TOOL_CONFIGS: Record<string, ToolConfig> = {
  // Git Repository Tools
  search_files: {
    name: 'search_files',
    displayName: 'Search Files',
    description: 'Search through repository files',
    icon: Search,
    category: 'git',
  },
  add_file: {
    name: 'add_file',
    displayName: 'Add File',
    description: 'Add new file to repository',
    icon: Plus,
    category: 'git',
  },
  add_all_files: {
    name: 'add_all_files',
    displayName: 'Stage All',
    description: 'Stage all changes for commit',
    icon: Upload,
    category: 'git',
  },
  commit: {
    name: 'commit',
    displayName: 'Commit',
    description: 'Create a commit with changes',
    icon: Save,
    category: 'git',
  },
  rename_file: {
    name: 'rename_file',
    displayName: 'Rename File',
    description: 'Rename or move a file',
    icon: RotateCcw,
    category: 'git',
  },
  list_files: {
    name: 'list_files',
    displayName: 'List Files',
    description: 'List directory contents',
    icon: FolderOpen,
    category: 'git',
  },
  open_file: {
    name: 'open_file',
    displayName: 'Open File',
    description: 'Read file contents',
    icon: Eye,
    category: 'git',
  },
  write_file: {
    name: 'write_file',
    displayName: 'Write File',
    description: 'Write content to file',
    icon: Edit3,
    category: 'git',
  },
  status: {
    name: 'status',
    displayName: 'Git Status',
    description: 'Check repository status',
    icon: Activity,
    category: 'git',
  },
  push_origin: {
    name: 'push_origin',
    displayName: 'Push to Origin',
    description: 'Push changes to remote repository',
    icon: Upload,
    category: 'git',
  },
  // GitHub Tools
  create_pr: {
    name: 'create_pr',
    displayName: 'Create PR',
    description: 'Create pull request',
    icon: GitPullRequest,
    category: 'github',
  },
  // Agent Actions
  acknowledge: {
    name: 'acknowledge',
    displayName: 'Acknowledge',
    description: 'Acknowledge notification or message',
    icon: Check,
    category: 'agent',
  },
  reply: {
    name: 'reply',
    displayName: 'Reply',
    description: 'Reply to conversation or issue',
    icon: MessageCircle,
    category: 'agent',
  },
  edit_comment: {
    name: 'edit_comment',
    displayName: 'Edit Comment',
    description: 'Edit existing comment',
    icon: Edit3,
    category: 'agent',
  },
  update_issue_description: {
    name: 'update_issue_description',
    displayName: 'Update Issue',
    description: 'Update issue description',
    icon: RefreshCw,
    category: 'agent',
  },
}

// Category metadata
export const TOOL_CATEGORIES = {
  git: {
    name: 'Git Repository',
    description: 'File and repository operations',
    color: 'text-muted-foreground',
    bgColor: 'bg-muted/30',
    borderColor: 'border-border',
  },
  github: {
    name: 'GitHub',
    description: 'GitHub platform interactions',
    color: 'text-muted-foreground',
    bgColor: 'bg-secondary/50',
    borderColor: 'border-border',
  },
  agent: {
    name: 'Agent Actions',
    description: 'AI agent responses and actions',
    color: 'text-muted-foreground',
    bgColor: 'bg-accent/30',
    borderColor: 'border-border',
  },
} as const

// Utility functions
export function getToolConfig(toolName: string): ToolConfig {
  return (
    TOOL_CONFIGS[toolName] || {
      name: toolName,
      displayName: toolName
        .replace(/_/g, ' ')
        .replace(/\b\w/g, (l) => l.toUpperCase()),
      description: `Execute ${toolName} operation`,
      icon: Bot,
      category: 'agent',
    }
  )
}

export function getToolStatusColor(status: ToolStatus): string {
  switch (status) {
    case 'success':
      return 'text-muted-foreground'
    case 'error':
      return 'text-destructive'
    case 'pending':
      return 'text-muted-foreground'
    case 'running':
      return 'text-accent-foreground'
    default:
      return 'text-muted-foreground'
  }
}

export function getToolStatusBadgeClass(status: ToolStatus): string {
  switch (status) {
    case 'success':
      return 'bg-muted text-muted-foreground border border-border'
    case 'error':
      return 'bg-destructive/10 text-destructive border border-destructive/20'
    case 'pending':
      return 'bg-secondary text-secondary-foreground border border-border'
    case 'running':
      return 'bg-accent text-accent-foreground border border-border'
    default:
      return 'bg-muted text-muted-foreground border border-border'
  }
}

export function getToolStatusIcon(status: ToolStatus): LucideIcon {
  switch (status) {
    case 'success':
      return CheckCircle
    case 'error':
      return AlertCircle
    case 'running':
      return RefreshCw
    default:
      return Clock
  }
}

function truncateContent(
  content: string,
  maxLength: number = 100,
): {
  truncated: string
  isTruncated: boolean
} {
  if (content.length <= maxLength) {
    return { truncated: content, isTruncated: false }
  }
  return {
    truncated: `${content.slice(0, maxLength)}...`,
    isTruncated: true,
  }
}

// Helper function to safely convert unknown arguments to string
function formatArguments(args: unknown): string {
  if (typeof args === 'string') {
    return args
  }
  try {
    return JSON.stringify(args, null, 2) || 'No arguments'
  } catch {
    return 'Invalid arguments'
  }
}

// Component to display tool calls with enhanced design
export function ToolCallDisplay({ toolCall }: { toolCall: ToolCall }) {
  const [isExpanded, setIsExpanded] = useState(false)
  const toolConfig = getToolConfig(toolCall.name)
  const category = TOOL_CATEGORIES[toolConfig.category]
  const IconComponent = toolConfig.icon
  const formattedArgs = formatArguments(toolCall.arguments)
  const { truncated, isTruncated } = truncateContent(formattedArgs, 200)

  const copyToClipboard = () => {
    navigator.clipboard.writeText(formattedArgs)
  }

  return (
    <div
      className={cn(
        'mt-3 rounded-lg border transition-all duration-200',
        category.bgColor,
        category.borderColor,
      )}
    >
      <div className='p-3'>
        <div className='flex items-start justify-between gap-2'>
          <div className='flex items-center gap-2 min-w-0 flex-1'>
            <div className={cn('p-1.5 rounded-md', category.bgColor)}>
              <IconComponent className={cn('h-4 w-4', category.color)} />
            </div>
            <div className='min-w-0 flex-1'>
              <div className='flex items-center gap-2'>
                <h4 className='font-medium text-sm'>
                  {toolConfig.displayName}
                </h4>
                <Badge variant='secondary' className='text-xs'>
                  {category.name}
                </Badge>
              </div>
              <p className='text-xs text-muted-foreground mt-1'>
                {toolConfig.description}
              </p>
            </div>
          </div>
          <div className='flex items-center gap-1'>
            <Button
              variant='ghost'
              size='sm'
              onClick={copyToClipboard}
              className='h-6 w-6 p-0'
            >
              <Copy className='h-3 w-3' />
            </Button>
            {isTruncated && (
              <Button
                variant='ghost'
                size='sm'
                onClick={() => setIsExpanded(!isExpanded)}
                className='h-6 w-6 p-0'
              >
                {isExpanded ? (
                  <ChevronUp className='h-3 w-3' />
                ) : (
                  <ChevronDown className='h-3 w-3' />
                )}
              </Button>
            )}
          </div>
        </div>

        {toolCall.arguments != null && (
          <div className='mt-3'>
            <div className='text-xs text-muted-foreground mb-1'>Arguments:</div>
            <div className='bg-muted/30 rounded-md p-2 font-mono text-xs'>
              <pre className='whitespace-pre-wrap'>
                {isExpanded ? formattedArgs : truncated}
              </pre>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

// Component to display tool results with enhanced design
export function ToolResultDisplay({ toolResult }: { toolResult: ToolResult }) {
  const [isExpanded, setIsExpanded] = useState(false)
  const toolConfig = getToolConfig(toolResult.name)
  const StatusIcon = getToolStatusIcon('success')
  const { truncated, isTruncated } = truncateContent(toolResult.content, 300)

  const copyToClipboard = () => {
    navigator.clipboard.writeText(toolResult.content)
  }

  return (
    <div className='mt-3 rounded-lg border border-border bg-muted/30 transition-all duration-200'>
      <div className='p-3'>
        <div className='flex items-start justify-between gap-2'>
          <div className='flex items-center gap-2 min-w-0 flex-1'>
            <div className='p-1.5 rounded-md bg-muted'>
              <StatusIcon className='h-4 w-4 text-muted-foreground' />
            </div>
            <div className='min-w-0 flex-1'>
              <div className='flex items-center gap-2'>
                <h4 className='font-medium text-sm text-foreground'>
                  {toolConfig.displayName} Result
                </h4>
                <Badge className={getToolStatusBadgeClass('success')}>
                  Success
                </Badge>
              </div>
              <p className='text-xs text-muted-foreground mt-1'>
                Tool executed successfully
              </p>
            </div>
          </div>
          <div className='flex items-center gap-1'>
            <Button
              variant='ghost'
              size='sm'
              onClick={copyToClipboard}
              className='h-6 w-6 p-0'
            >
              <Copy className='h-3 w-3' />
            </Button>
            {isTruncated && (
              <Button
                variant='ghost'
                size='sm'
                onClick={() => setIsExpanded(!isExpanded)}
                className='h-6 w-6 p-0'
              >
                {isExpanded ? (
                  <ChevronUp className='h-3 w-3' />
                ) : (
                  <ChevronDown className='h-3 w-3' />
                )}
              </Button>
            )}
          </div>
        </div>

        <div className='mt-3'>
          <div className='text-xs text-muted-foreground mb-1'>Output:</div>
          <div className='bg-card rounded-md p-2 font-mono text-xs border border-border'>
            <pre className='whitespace-pre-wrap text-foreground'>
              {isExpanded ? toolResult.content : truncated}
            </pre>
          </div>
        </div>
      </div>
    </div>
  )
}
