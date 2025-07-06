import type { Message, ToolCall, ToolResult } from '@/hooks/use-agent-channel'

// Combined tool execution represents both the call and its result
export type CombinedToolExecution = {
  call_id: string
  name: string
  status: 'pending' | 'running' | 'success' | 'error'
  toolCall: ToolCall
  toolResult?: ToolResult
  error?: string
}

// Enhanced message type with combined tool executions
export type ProcessedMessage = Omit<Message, 'tool_calls' | 'tool_results'> & {
  combinedToolExecutions: CombinedToolExecution[]
}

/**
 * Processes an array of messages to combine tool calls and results across messages
 * This reduces the message array by merging tool calls with their corresponding results
 * from subsequent messages
 */
export function processMessages(messages: Message[]): ProcessedMessage[] {
  const processedMessages: ProcessedMessage[] = []
  const toolCallsAwaitingResults = new Map<
    string,
    { messageIndex: number; toolCall: ToolCall }
  >()

  for (let i = 0; i < messages.length; i++) {
    const message = messages[i]
    const hasToolCalls = message.tool_calls && message.tool_calls.length > 0
    const hasToolResults =
      message.tool_results && message.tool_results.length > 0

    // If this message has tool calls, process them
    if (hasToolCalls) {
      // Create combined tool executions for this message
      const combinedToolExecutions: CombinedToolExecution[] = []

      for (const toolCall of message.tool_calls) {
        // Track this tool call for future result matching
        toolCallsAwaitingResults.set(toolCall.call_id, {
          messageIndex: processedMessages.length,
          toolCall,
        })

        // Create initial combined execution (will be updated when result arrives)
        const status: CombinedToolExecution['status'] =
          toolCall.status === 'running'
            ? 'running'
            : toolCall.status === 'error'
              ? 'error'
              : 'pending'

        combinedToolExecutions.push({
          call_id: toolCall.call_id,
          name: toolCall.name,
          status,
          toolCall,
          toolResult: undefined,
        })
      }

      // Add processed message with tool calls
      processedMessages.push({
        ...message,
        combinedToolExecutions,
      })
    }
    // If this message has tool results, merge them with previous tool calls
    else if (hasToolResults) {
      let resultsMerged = false

      for (const toolResult of message.tool_results || []) {
        const awaitingCall = toolCallsAwaitingResults.get(
          toolResult.tool_call_id,
        )

        if (awaitingCall) {
          // Find the message with the corresponding tool call and update it
          const targetMessage = processedMessages[awaitingCall.messageIndex]
          const toolExecutionIndex =
            targetMessage.combinedToolExecutions.findIndex(
              (exec) => exec.call_id === toolResult.tool_call_id,
            )

          if (toolExecutionIndex !== -1) {
            // Update the combined execution with the result
            targetMessage.combinedToolExecutions[toolExecutionIndex] = {
              ...targetMessage.combinedToolExecutions[toolExecutionIndex],
              status: 'success',
              toolResult,
            }
            resultsMerged = true
          }

          // Remove from waiting list
          toolCallsAwaitingResults.delete(toolResult.tool_call_id)
        }
      }

      // If no results were merged (orphaned results), create a standalone message
      if (!resultsMerged) {
        const combinedToolExecutions: CombinedToolExecution[] = []

        for (const result of message.tool_results || []) {
          // Create a synthetic tool call for orphaned results
          const syntheticToolCall: ToolCall = {
            index: -1,
            name: result.name,
            status: 'completed',
            type: result.type,
            arguments: null,
            call_id: result.tool_call_id,
          }

          combinedToolExecutions.push({
            call_id: result.tool_call_id,
            name: result.name,
            status: 'success',
            toolCall: syntheticToolCall,
            toolResult: result,
          })
        }

        processedMessages.push({
          ...message,
          combinedToolExecutions,
        })
      }
      // If results were merged, we skip adding this message as a separate entry
    }
    // Regular message without tool calls or results
    else {
      processedMessages.push({
        ...message,
        combinedToolExecutions: [],
      })
    }
  }

  return processedMessages
}
