import { useCallback, useEffect } from 'react'
import { usePhoenixChannel } from './use-phoenix-channel'

// Types for message content
export type MessageContent = {
  type: string
  content: string
}

// Types for tool results
export type ToolResult = {
  name: string
  type: string
  content: string
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
  | { event: 'delta'; payload: { delta: string } }
  | { event: 'message'; payload: Message }
  | {
      event: 'phx_reply'
      payload: { status: string; response: { messages: MessageRecord[] } }
    }

const initialState: State = {
  messages: [],
  lastPartialMessage: '',
}

function agentChannelReducer(
  state: State,
  action: { event: string; payload: EventPayload },
): State {
  // Cast to narrower type
  const event = action as Event

  switch (event.event) {
    case 'delta':
      return {
        ...state,
        lastPartialMessage: state.lastPartialMessage + event.payload.delta,
      }
    case 'message':
      return {
        ...state,
        messages: [...state.messages, event.payload],
        lastPartialMessage: '', // clear delta on new message
      }
    case 'phx_reply':
      // Handle Phoenix reply events
      if (event.payload.status === 'ok' && event.payload.response?.messages) {
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

/**
 * useAgentChannel
 *
 * @param agentId - The agent's id (string)
 * @param initialMessages - Optional initial messages array
 * @returns { state, sendMessage, broadcast }
 */
export function useAgentChannel(agentId: string, fetchInitialMessages = true) {
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
    if (isJoined && fetchInitialMessages) {
      broadcast('messages')
    }
  }, [isJoined, broadcast, fetchInitialMessages])

  return {
    state,
    sendMessage,
    broadcast,
  }
}
