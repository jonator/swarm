import {
  useEffect,
  useReducer,
  useState,
  type Reducer,
  type ActionDispatch,
} from 'react'
import { useSocket } from '@/context/socket'
import { useTemporaryToken } from '@/lib/queries/hooks/token'
import type { Socket } from 'phoenix'

function mustJoinChannelWarning() {
  return () =>
    console.error(
      'usePhoenixChannel broadcast function cannot be invoked before the channel has been joined',
    )
}

function joinChannel<EventPayload = unknown>(
  socket: Socket | null,
  topic: string,
  token: string | undefined,
  dispatch: ActionDispatch<[{ event: string; payload: EventPayload }]>,
  setBroadcast: (
    broadcast: (event: string, payload: EventPayload) => void,
  ) => void,
) {
  if (!socket || !topic) return

  // Join the channel
  const channel = socket.channel(topic, { token })

  // Dispatch the event to the reducer
  channel.onMessage = (event: string, payload: EventPayload) => {
    dispatch({ event, payload })
    return payload
  }

  channel
    .join()
    .receive('ok', ({ messages }: { messages?: unknown }) =>
      console.info('Successfully joined channel', messages || ''),
    )
    .receive('error', ({ reason }: { reason: unknown }) =>
      console.error('Failed to join channel', reason),
    )

  setBroadcast(() => channel.push.bind(channel))

  return () => {
    channel.leave()
  }
}

/**
 * usePhoenixChannel (v2)
 *
 * A wrapper around useChannel from 'use-phoenix-channel' for backward compatibility.
 *
 * @param topic - The channel/topic name (e.g. 'agent:123')
 * @param reducer - A reducer function (state, {event, payload}) => newState
 * @param initialState - The initial state for the channel
 * @returns [state, broadcast]
 *
 * ### Joining and broadcasting:
 * ```tsx
 * const [state, broadcast] = usePhoenixChannel(topic, reducer, initialState)
 *
 * // To broadcast:
 * broadcast('event', { ...payload })
 * ```
 *
 * ### Managing state
 * ```tsx
 * const channelName = 'counter:example'
 * const countReducer = (state, {event, payload}) => {
 *   // the second argument is the message sent over the channel
 *   // it will contain an event key and a payload key
 *   switch(event) {
 *     case 'increment':
 *       return state + payload.amount
 *     case 'decrement':
 *       return state - payload.amount
 *     default:
 *       return state
 *   }
 * }
 * const initialState = 0
 *
 * const MyComponent = (props) => {
 *   const [{ count }, broadcast] = useChannel(channelName, countReducer, initialState)
 *
 *   return (
 *     <div>
 *       <h1>{`The value below will update in realtime as the count is changed by other subscribers to the {channelName} channel`}</h1>
 *       { count }
 *     </div>
 *   )
 * }
 * ```
 */
export function usePhoenixChannel<State = unknown, EventPayload = unknown>(
  topic: string,
  reducer: Reducer<State, { event: string; payload: EventPayload }>,
  initialState: State,
  enabled: boolean = true,
): [State, (event: string, payload: EventPayload) => void] {
  const { socket } = useSocket()
  const [state, dispatch] = useReducer(reducer, initialState)
  const { data: tokenData } = useTemporaryToken()
  const token = tokenData?.token
  const [broadcast, setBroadcast] = useState<
    (event: string, payload: EventPayload) => void
  >(mustJoinChannelWarning)

  useEffect(() => {
    if (enabled) {
      joinChannel(socket, topic, token, dispatch, setBroadcast)
    }
  }, [socket, topic, token, enabled])

  return [state, broadcast]
}
