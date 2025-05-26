'use client'

import { submitLinearAuthCode } from '@/actions/auth'
import SwarmLogo from '@/components/swarm-logo'
import { cn } from '@/lib/utils/shadcn'
import { type PropsWithChildren, useEffect, useState } from 'react'

export default function LinearCallbackPage() {
  const [isError, setIsError] = useState(false)

  useEffect(() => {
    const searchParams = new URLSearchParams(window.location.search)

    const code = searchParams.get('code')
    const state = searchParams.get('state')

    if (state !== localStorage.getItem('linear_auth_state')) {
      setIsError(true)
      setTimeout(() => {
        window.close()
      }, 3_000)
      return
    }

    if (!code) {
      return window.close()
    }

    submitLinearAuthCode(code)
      .then(() => {
        window.close()
      })
      .catch((error: unknown) => {
        console.error('Authentication failed:', error)
        setIsError(true)
      })
  }, [])

  if (isError) {
    return <SwarmDisplay>Error authenticating with Linear</SwarmDisplay>
  }

  return <SwarmDisplay loading>Authenticating...</SwarmDisplay>
}

const SwarmDisplay = ({
  loading = false,
  children,
}: PropsWithChildren<{ loading?: boolean }>) => (
  <div className='bg-background flex min-h-svh flex-col items-center justify-center gap-6 p-6 md:p-10'>
    <div className='w-full max-w-sm'>
      <div className='flex flex-col gap-6'>
        <div className='flex flex-col items-center gap-2'>
          <a
            href='/'
            className='flex flex-col items-center gap-2 font-medium text-foreground'
          >
            <div className='flex size-8 items-center justify-center rounded-md'>
              <SwarmLogo />
            </div>
            <span className='sr-only'>Swarm</span>
          </a>
          <h1 className='text-xl font-bold text-foreground'>
            Welcome to Swarm
          </h1>
        </div>
        <div
          className={cn(
            'flex flex-col gap-6 text-center',
            loading && 'animate-pulse',
          )}
        >
          {children}
        </div>
      </div>
    </div>
  </div>
)
