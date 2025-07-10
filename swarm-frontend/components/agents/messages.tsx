'use client'

import { useAgentChannel } from '@/hooks/use-agent-channel'
import type { MessageContent } from '@/hooks/use-agent-channel'
import type { ProcessedMessage } from '@/lib/models/messages'
import { cn } from '@/lib/utils/shadcn'
import { Bot, MessageSquare, RefreshCw, User, Zap } from 'lucide-react'
import { CombinedToolExecutionDisplay } from './tools'
import { motion } from 'motion/react'
import { useScrollToBottom } from '@/hooks/use-scroll-to-bottom'
import { useEffect } from 'react'

// Helper function to extract text content from message content (string or array)
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

// Enhanced usage display component
function UsageDisplay({ message }: { message: ProcessedMessage }) {
  if (!message.metadata?.usage) return null

  const { input, output } = message.metadata.usage

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

// Enhanced message role display
function MessageRoleDisplay({ role }: { role: string }) {
  const roleConfig = {
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
  }

  const config =
    roleConfig[role as keyof typeof roleConfig] || roleConfig.system
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

interface AgentMessagesProps {
  agentId: string
}

export function AgentMessages({ agentId }: AgentMessagesProps) {
  const {
    endRef,
    isAtBottom,
    scrollToBottom,
    onViewportEnter,
    onViewportLeave,
  } = useScrollToBottom()

  const { messages, lastPartialMessage } = useAgentChannel(agentId)

  // Auto-scroll to bottom when new messages arrive or partial message updates
  useEffect(() => {
    // Always scroll to bottom for new messages if user was at bottom, or if it's the first message
    if (messages.length > 0 && (isAtBottom || messages.length === 1)) {
      scrollToBottom()
    }
  }, [messages.length, isAtBottom, scrollToBottom])

  // Auto-scroll when partial message updates if user is at bottom
  useEffect(() => {
    if (lastPartialMessage && isAtBottom) {
      scrollToBottom()
    }
  }, [lastPartialMessage, isAtBottom, scrollToBottom])

  return (
    <div className='space-y-4 p-4'>
      {messages.map((message, messageIndex) => {
        const textContent = extractTextContent(message.raw_content)

        return (
          <div
            key={message.index ?? messageIndex}
            className={cn(
              'p-4 rounded-xl border transition-all duration-200',
              message.role === 'user'
                ? 'bg-card border-border'
                : message.role === 'assistant'
                  ? 'bg-muted/30 border-border'
                  : 'bg-secondary/30 border-border',
            )}
          >
            <MessageRoleDisplay role={message.role} />

            {textContent && (
              <div className='text-sm whitespace-pre-wrap leading-relaxed mb-3'>
                {textContent}
              </div>
            )}

            {/* Display combined tool executions */}
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

            {/* Display usage metadata */}
            <UsageDisplay message={message} />
          </div>
        )
      })}

      {/* Show partial message if it exists */}
      {lastPartialMessage && (
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
            {lastPartialMessage}
          </div>
        </div>
      )}

      {messages.length === 0 && !lastPartialMessage && (
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
      )}

      <motion.div
        ref={endRef}
        className='shrink-0 min-w-[24px] min-h-[24px]'
        onViewportLeave={onViewportLeave}
        onViewportEnter={onViewportEnter}
      />
    </div>
  )
}
