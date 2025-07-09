'use client'

import { useAgentChannel } from '@/hooks/use-agent-channel'
import type { MessageContent } from '@/hooks/use-agent-channel'
import { type ProcessedMessage, processMessages } from '@/lib/models/messages'
import { cn } from '@/lib/utils/shadcn'
import { Bot, MessageSquare, RefreshCw, User, Zap } from 'lucide-react'
import { CombinedToolExecutionDisplay } from './tools'

interface AgentMessagesProps {
  agentId: string
}

/**
 * Configuration for different message roles
 */
const MESSAGE_ROLE_CONFIG = {
  user: {
    icon: User,
    color: 'text-foreground',
    bgColor: 'bg-muted',
  },
  assistant: {
    icon: Bot,
    color: 'text-foreground',
    bgColor: 'bg-muted',
  },
  system: {
    icon: MessageSquare,
    color: 'text-foreground',
    bgColor: 'bg-muted',
  },
} as const

/**
 * Extracts plain text content from message content that can be either
 * a string or an array of content objects.
 * 
 * @param content - The message content to extract text from
 * @returns Plain text string
 */
function extractTextContent(content: string | MessageContent[]): string {
  if (typeof content === 'string') {
    return content
  }

  if (Array.isArray(content)) {
    return content
      .filter((item) => item.type === 'text')
      .map((item) => item.content)
      .join('\n')
  }

  return ''
}

/**
 * Displays token usage information for a message
 */
function UsageDisplay({ message }: { message: ProcessedMessage }) {
  const usage = message.metadata?.usage
  
  if (!usage) {
    return null
  }

  const { input, output } = usage

  return (
    <div className='mt-3 flex items-center gap-3 text-xs text-muted-foreground bg-muted/30 rounded-md p-2'>
      <div className='flex items-center gap-1'>
        <Zap className='h-3 w-3' />
        <span>Tokens:</span>
      </div>
      
      <div className='flex items-center gap-1'>
        <span className='font-mono'>{input}</span>
        <span>in</span>
      </div>
      
      <div className='w-px h-3 bg-muted-foreground/30' />
      
      <div className='flex items-center gap-1'>
        <span className='font-mono'>{output}</span>
        <span>out</span>
      </div>
    </div>
  )
}

/**
 * Displays the role indicator for a message
 */
function MessageRoleDisplay({ role }: { role: string }) {
  const config = MESSAGE_ROLE_CONFIG[role as keyof typeof MESSAGE_ROLE_CONFIG] || MESSAGE_ROLE_CONFIG.system
  const IconComponent = config.icon

  return (
    <div className='flex items-center gap-2 mb-3'>
      <div className={cn('p-1.5 rounded-md', config.bgColor)}>
        <IconComponent className={cn('h-4 w-4', config.color)} />
      </div>
      
      <div className='flex items-center gap-2'>
        <span className={cn('text-sm font-medium capitalize', config.color)}>
          {role}
        </span>
      </div>
    </div>
  )
}

/**
 * Displays a single message with its content and metadata
 */
function MessageDisplay({ message, messageIndex }: { message: ProcessedMessage; messageIndex: number }) {
  const textContent = extractTextContent(message.raw_content)
  const messageKey = message.index ?? messageIndex

  const messageClasses = cn(
    'p-4 rounded-xl border transition-all duration-200',
    {
      'bg-card border-border': message.role === 'user',
      'bg-muted/30 border-border': message.role === 'assistant',
      'bg-secondary/30 border-border': message.role === 'system',
    }
  )

  return (
    <div key={messageKey} className={messageClasses}>
      <MessageRoleDisplay role={message.role} />

      {textContent && (
        <div className='text-sm whitespace-pre-wrap leading-relaxed mb-3'>
          {textContent}
        </div>
      )}

      {message.combinedToolExecutions.length > 0 && (
        <div className='space-y-2'>
          {message.combinedToolExecutions.map((toolExecution) => (
            <CombinedToolExecutionDisplay
              key={toolExecution.call_id}
              toolExecution={toolExecution}
            />
          ))}
        </div>
      )}

      <UsageDisplay message={message} />
    </div>
  )
}

/**
 * Displays a partial message that's currently being generated
 */
function PartialMessageDisplay({ content }: { content: string }) {
  return (
    <div className='p-4 rounded-xl border bg-muted/30 border-border'>
      <div className='flex items-center gap-2 mb-3'>
        <div className='p-1.5 rounded-md bg-muted'>
          <Bot className='h-4 w-4 text-foreground' />
        </div>
        
        <div className='flex items-center gap-2'>
          <span className='text-sm font-medium text-foreground'>
            Assistant
          </span>
          
          <div className='flex items-center gap-1'>
            <RefreshCw className='h-3 w-3 text-muted-foreground animate-spin' />
            <span className='text-xs text-muted-foreground'>
              Thinking...
            </span>
          </div>
        </div>
      </div>
      
      <div className='text-sm whitespace-pre-wrap leading-relaxed'>
        {content}
      </div>
    </div>
  )
}

/**
 * Displays an empty state when no messages are available
 */
function EmptyMessagesState() {
  return (
    <div className='text-center py-12'>
      <div className='inline-flex items-center justify-center w-16 h-16 rounded-full bg-muted/30 mb-4'>
        <MessageSquare className='h-8 w-8 text-muted-foreground' />
      </div>
      
      <h3 className='text-lg font-medium text-muted-foreground mb-2'>
        No messages yet
      </h3>
      
      <p className='text-sm text-muted-foreground'>
        Start a conversation with your agent to see messages here
      </p>
    </div>
  )
}

/**
 * Main component for displaying agent messages
 * 
 * Connects to the agent channel and displays all messages,
 * including partial messages that are currently being generated.
 */
export function AgentMessages({ agentId }: AgentMessagesProps) {
  const { state } = useAgentChannel(agentId)
  const processedMessages = processMessages(state.messages)

  const hasMessages = processedMessages.length > 0 || state.lastPartialMessage

  return (
    <div className='space-y-4 p-4'>
      {processedMessages.map((message, messageIndex) => (
        <MessageDisplay
          key={message.index ?? messageIndex}
          message={message}
          messageIndex={messageIndex}
        />
      ))}

      {state.lastPartialMessage && (
        <PartialMessageDisplay content={state.lastPartialMessage} />
      )}

      {!hasMessages && <EmptyMessagesState />}
    </div>
  )
}