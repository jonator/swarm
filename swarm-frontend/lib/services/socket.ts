import { Socket } from 'phoenix'

class SocketManager {
  private socket: Socket | null = null
  private isConnecting = false
  private reconnectAttempts = 0
  private maxReconnectAttempts = 5
  private reconnectDelay = 1000

  constructor() {
    this.handleVisibilityChange = this.handleVisibilityChange.bind(this)
    this.handleOnline = this.handleOnline.bind(this)
    this.handleOffline = this.handleOffline.bind(this)
  }

  initialize(token: string): Socket {
    if (this.socket?.isConnected()) {
      return this.socket
    }

    if (!process.env.NEXT_PUBLIC_API_BASE_URL) {
      throw new Error('NEXT_PUBLIC_API_BASE_URL is not set')
    }

    this.socket = new Socket(`${process.env.NEXT_PUBLIC_API_BASE_URL}/socket`, {
      params: { token },
      logger: (kind, msg, data) => {
        if (process.env.NODE_ENV === 'development') {
          console.log(`Phoenix ${kind}: ${msg}`, data)
        }
      },
      transport: WebSocket,
      timeout: 10000,
      heartbeatIntervalMs: 30000,
      rejoinAfterMs: (tries) => {
        if (tries > this.maxReconnectAttempts) {
          this.handleMaxReconnectAttemptsReached()
          return 30000 // Try again in 30 seconds
        }
        return [1000, 2000, 5000, 10000][tries - 1] || 10000
      },
    })

    this.setupEventListeners()
    this.socket.connect()

    return this.socket
  }

  private setupEventListeners() {
    if (!this.socket) return

    this.socket.onOpen(() => {
      console.log('Phoenix socket connected')
      this.reconnectAttempts = 0
      this.isConnecting = false
    })

    this.socket.onError((error) => {
      if (JSON.stringify(error) === '{}') return
      console.error('Phoenix socket error:', error)
    })

    this.socket.onClose((event) => {
      console.log('Phoenix socket closed:', event)
      this.handleDisconnect()
    })

    // Browser event listeners
    document.addEventListener('visibilitychange', this.handleVisibilityChange)
    window.addEventListener('online', this.handleOnline)
    window.addEventListener('offline', this.handleOffline)
  }

  private handleVisibilityChange() {
    if (
      document.visibilityState === 'visible' &&
      this.socket &&
      !this.socket.isConnected()
    ) {
      this.reconnect()
    }
  }

  private handleOnline() {
    if (this.socket && !this.socket.isConnected()) {
      this.reconnect()
    }
  }

  private handleOffline() {
    console.log('Browser is offline')
  }

  private handleDisconnect() {
    if (
      this.reconnectAttempts < this.maxReconnectAttempts &&
      !this.isConnecting
    ) {
      this.reconnect()
    }
  }

  private handleMaxReconnectAttemptsReached() {
    console.error(
      `Max reconnect attempts (${this.maxReconnectAttempts}) reached`,
    )
    // You could show a user notification here
  }

  private reconnect() {
    if (this.isConnecting || !this.socket) return

    this.isConnecting = true
    this.reconnectAttempts++

    setTimeout(() => {
      if (this.socket && !this.socket.isConnected()) {
        console.log(`Reconnecting... (attempt ${this.reconnectAttempts})`)
        this.socket.connect()
      }
      this.isConnecting = false
    }, this.reconnectDelay * this.reconnectAttempts)
  }

  getSocket(): Socket | null {
    return this.socket
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect()
      this.socket = null
    }

    // Remove event listeners
    document.removeEventListener(
      'visibilitychange',
      this.handleVisibilityChange,
    )
    window.removeEventListener('online', this.handleOnline)
    window.removeEventListener('offline', this.handleOffline)
  }

  isConnected(): boolean {
    return this.socket?.isConnected() ?? false
  }
}

// Export singleton instance
export const socketManager = new SocketManager()
