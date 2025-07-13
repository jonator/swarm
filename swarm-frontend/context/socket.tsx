'use client'

import type { Socket } from 'phoenix'
import type React from 'react'
import { createContext, useContext, useEffect, useState } from 'react'
import { useTemporaryToken } from '@/lib/queries/hooks/token'
import { socketManager } from '@/lib/services/socket'

interface SocketContextType {
  socket: Socket | null
  isConnected: boolean
  connectionError: string | null
}

const SocketContext = createContext<SocketContextType>({
  socket: null,
  isConnected: false,
  connectionError: null,
})

export const useSocket = () => {
  const context = useContext(SocketContext)
  if (!context) {
    throw new Error('useSocket must be used within a SocketProvider')
  }
  return context
}

interface SocketProviderProps {
  children: React.ReactNode
}

export const SocketProvider: React.FC<SocketProviderProps> = ({ children }) => {
  const [socket, setSocket] = useState<Socket | null>(null)
  const [isConnected, setIsConnected] = useState(false)
  const [connectionError, setConnectionError] = useState<string | null>(null)
  const { data: token, isLoading, error } = useTemporaryToken()

  useEffect(() => {
    if (!token) {
      setSocket(null)
      setIsConnected(false)
      return
    }

    try {
      const newSocket = socketManager.initialize(token.token)
      setSocket(newSocket)

      const handleOpen = () => {
        setIsConnected(true)
        setConnectionError(null)
      }

      const handleClose = () => {
        setIsConnected(false)
      }

      const handleError = (error: unknown) => {
        if (error instanceof Error) {
          setConnectionError(error.message)
        } else {
          setConnectionError('Connection error')
        }
      }

      newSocket.onOpen(handleOpen)
      newSocket.onClose(handleClose)
      newSocket.onError(handleError)

      return () => {
        newSocket.off(['open', 'close', 'error'])
      }
    } catch (error) {
      console.error('Failed to initialize socket:', error)
      setConnectionError('Failed to initialize connection')
    }
  }, [token])

  useEffect(() => {
    return () => {
      socketManager.disconnect()
    }
  }, [])

  if (isLoading) {
    return null // or a loading spinner if desired
  }

  if (error) {
    return null // or an error message if desired
  }

  return (
    <SocketContext.Provider value={{ socket, isConnected, connectionError }}>
      {children}
    </SocketContext.Provider>
  )
}
