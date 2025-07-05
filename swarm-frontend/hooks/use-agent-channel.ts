import { useCallback } from 'react'
import { usePhoenixChannel } from './use-phoenix-channel'

// Types for LangChain.Message (minimal)
export type Message = {
  index: number
  role: string // 'system' | 'user' | 'assistant' | 'tool', but as string
  content: string
}

export type State = {
  messages: Message[]
  lastPartialMessage: string
}

type EventPayload = { delta: string } | Message

type Event =
  | { event: 'delta'; payload: { delta: string } }
  | { event: 'message'; payload: Message }

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
export function useAgentChannel(
  agentId: string,
  initialMessages: Message[] = [],
) {
  const topic = `agent:${agentId}`
  const [state, broadcast] = usePhoenixChannel<State, EventPayload>(
    topic,
    agentChannelReducer,
    {
      ...initialState,
      messages: initialMessages,
    },
  )

  // Send a user message to the agent
  const sendMessage = useCallback(
    (message: Message) => {
      broadcast('user_msg', message)
    },
    [broadcast],
  )

  return {
    state,
    sendMessage,
    broadcast,
  }
}
