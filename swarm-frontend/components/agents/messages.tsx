'use client'

import { useAgentChannel } from '@/hooks/use-agent-channel'
import type {
  Message,
  MessageContent,
  ToolCall,
  ToolResult,
} from '@/hooks/use-agent-channel'
import { cn } from '@/lib/utils/shadcn'
import { Wrench, Zap, CheckCircle } from 'lucide-react'

interface AgentMessagesProps {
  agentId: string
}

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

// Component to display tool calls
function ToolCallDisplay({ toolCall }: { toolCall: ToolCall }) {
  return (
    <div className='mt-2 p-2 bg-muted/50 rounded border border-muted-foreground/20'>
      <div className='flex items-center gap-2 mb-1'>
        <Wrench className='h-3 w-3 text-muted-foreground' />
        <span className='text-xs font-medium'>{toolCall.name}</span>
      </div>
      {toolCall.arguments != null && (
        <div className='text-xs text-muted-foreground font-mono'>
          {formatArguments(toolCall.arguments)}
        </div>
      )}
    </div>
  )
}

// Component to display tool results
function ToolResultDisplay({ toolResult }: { toolResult: ToolResult }) {
  return (
    <div className='mt-2 p-2 bg-green-50 dark:bg-green-900/20 rounded border border-green-200 dark:border-green-800'>
      <div className='flex items-center gap-2 mb-1'>
        <CheckCircle className='h-3 w-3 text-green-600' />
        <span className='text-xs font-medium text-green-800 dark:text-green-200'>
          {toolResult.name} result
        </span>
      </div>
      <div className='text-xs text-green-700 dark:text-green-300 font-mono whitespace-pre-wrap max-h-32 overflow-y-auto'>
        {toolResult.content}
      </div>
    </div>
  )
}

// Component to display usage metadata
function UsageDisplay({ message }: { message: Message }) {
  if (!message.metadata?.usage) return null

  const { input, output } = message.metadata.usage

  return (
    <div className='mt-2 flex items-center gap-2 text-xs text-muted-foreground'>
      <Zap className='h-3 w-3' />
      <span>{input} in</span>
      <span>•</span>
      <span>{output} out</span>
    </div>
  )
}

export function AgentMessages({ agentId }: AgentMessagesProps) {
  const { state } = useAgentChannel(agentId)

  console.log('state', state)

  return (
    <div className='space-y-3 p-4'>
      {state.messages.map((message, messageIndex) => {
        const textContent = extractTextContent(message.content)

        return (
          <div
            key={message.index ?? messageIndex}
            className={cn(
              'p-3 rounded-lg border',
              message.role === 'user'
                ? 'bg-primary/5 border-primary/20'
                : message.role === 'assistant'
                  ? 'bg-secondary/50 border-secondary'
                  : 'bg-muted border-muted-foreground/20',
            )}
          >
            <div className='flex items-center gap-2 mb-2'>
              <span className='text-xs font-medium uppercase tracking-wide text-muted-foreground'>
                {message.role}
              </span>
              {message.index !== null && (
                <span className='text-xs text-muted-foreground'>
                  #{message.index}
                </span>
              )}
            </div>

            {textContent && (
              <div className='text-sm whitespace-pre-wrap'>{textContent}</div>
            )}

            {/* Display tool calls if they exist */}
            {message.tool_calls && message.tool_calls.length > 0 && (
              <div className='mt-2 space-y-1'>
                {message.tool_calls.map((toolCall) => (
                  <ToolCallDisplay key={toolCall.call_id} toolCall={toolCall} />
                ))}
              </div>
            )}

            {/* Display tool results if they exist */}
            {message.tool_results && message.tool_results.length > 0 && (
              <div className='mt-2 space-y-1'>
                {message.tool_results.map((toolResult) => (
                  <ToolResultDisplay
                    key={toolResult.tool_call_id}
                    toolResult={toolResult}
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
      {state.lastPartialMessage && (
        <div className='p-3 rounded-lg border bg-secondary/30 border-secondary/50'>
          <div className='flex items-center gap-2 mb-2'>
            <span className='text-xs font-medium uppercase tracking-wide text-muted-foreground'>
              assistant
            </span>
            <span className='text-xs text-muted-foreground animate-pulse'>
              typing...
            </span>
          </div>
          <div className='text-sm whitespace-pre-wrap'>
            {state.lastPartialMessage}
          </div>
        </div>
      )}

      {state.messages.length === 0 && !state.lastPartialMessage && (
        <div className='text-center py-8 text-muted-foreground'>
          No messages yet
        </div>
      )}
    </div>
  )
}
