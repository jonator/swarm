import { useCallback, useEffect, useMemo } from 'react'
import { usePhoenixChannel } from './use-phoenix-channel'
import { processMessages } from '@/lib/models/messages'

// Types for message content
export type MessageContent = {
  type: string
  content: string
}

// Types for tool results
export type ToolResult = {
  name: string
  type: string
  content:
    | string
    | Array<{
        content: string
        type: string
        options: unknown[]
      }>
  tool_call_id: string
}

// Types for tool calls
export type ToolCall = {
  index: number
  name: string
  status: string
  type: string
  arguments: unknown
  call_id: string
}

// Types for metadata
export type MessageMetadata = {
  usage: {
    input: number
    output: number
    raw: {
      cache_creation_input_tokens: number
      cache_read_input_tokens: number
      input_tokens: number
      output_tokens: number
      service_tier: string
    }
  }
}

// Updated Message type based on actual payload structure
export type Message = {
  index: number | null
  name: string | null
  status: string
  metadata: MessageMetadata | null
  role: string // 'system' | 'user' | 'assistant' | 'tool', but as string
  raw_content: string | MessageContent[] // Can be either string or array
  tool_calls: ToolCall[]
  tool_results: ToolResult[] | null
}

/** MessageRecord type is a Message that comes from syncing with DB. */
type MessageRecord = {
  id: string
  agent_id: string
  index: number
  role: string
  content: Message
  created_at: string
  updated_at: string
}

export type State = {
  messages: Message[]
  lastPartialMessage: string
}

type EventPayload =
  | { delta: string }
  | Message
  | { messages: Message[] }
  | { status: string; response: { messages: Message[] } }

type Event =
  | { event: 'message_delta'; payload: { delta: string } }
  | { event: 'message'; payload: Message }
  | {
      event: 'phx_reply'
      payload: { status: string; response: { messages: MessageRecord[] } }
    }

export type AgentChannelOptions = {
  fetchInitialMessages?: boolean
  onMessage?: (message: Message) => void
  onDelta?: (delta: string, fullPartialMessage: string) => void
  onMessagesLoaded?: (messages: Message[]) => void
  onStateChange?: (state: State) => void
}

const initialState: State = {
  messages: [],
  lastPartialMessage: '',
}

/**
 * useAgentChannel
 *
 * @param agentId - The agent's id (string)
 * @param initialMessages - Optional initial messages array
 * @returns { state, sendMessage, broadcast }
 */
export function useAgentChannel(agentId: string, opts?: AgentChannelOptions) {
  function agentChannelReducer(
    state: State,
    action: { event: string; payload: EventPayload },
  ): State {
    // Cast to narrower type
    const event = action as Event

    switch (event.event) {
      case 'message_delta':
        opts?.onDelta?.(event.payload.delta, state.lastPartialMessage)
        return {
          ...state,
          lastPartialMessage: state.lastPartialMessage + event.payload.delta,
        }
      case 'message':
        opts?.onMessage?.(event.payload)
        return {
          ...state,
          messages: [...state.messages, event.payload],
          lastPartialMessage: '', // clear delta on new message
        }
      case 'phx_reply':
        // Handle Phoenix reply events, which are equivalent to REST API calls
        if (event.payload.status === 'ok' && event.payload.response?.messages) {
          opts?.onMessagesLoaded?.(
            event.payload.response.messages.map(({ index, content }) => ({
              ...content,
              index,
            })),
          )
          return {
            ...state,
            messages: event.payload.response.messages.map(
              ({ index, content }) => ({
                ...content,
                index,
              }),
            ),
          }
        }
        return state
      default:
        return state
    }
  }

  const topic = `agent:${agentId}`
  const [state, broadcast, isJoined] = usePhoenixChannel(
    topic,
    agentChannelReducer,
    {
      ...initialState,
      messages: [],
    },
  )

  // Send a user message to the agent
  const sendMessage = useCallback(
    (message: Message) => {
      broadcast('user_message', message)
    },
    [broadcast],
  )

  useEffect(() => {
    if (isJoined && (opts?.fetchInitialMessages ?? true)) {
      broadcast('messages')
    }
  }, [isJoined, broadcast, opts?.fetchInitialMessages])

  const messages = useMemo(
    () => processMessages(state.messages),
    [state.messages],
  )

  return {
    lastPartialMessage: state.lastPartialMessage,
    messages,
    sendMessage,
    broadcast,
  }
}
