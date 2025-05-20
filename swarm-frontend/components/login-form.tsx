'use client'

import { routeEntry } from '@/actions/routing'
import Image from 'next/image'
import { useState } from 'react'
import { cn } from '../lib/utils/shadcn'
import SwarmLogo from './swarm-logo'
import { Button } from './ui/button'

export function LoginForm({
  className,
  ...props
}: React.ComponentProps<'div'>) {
  const [isAuthenticating, setIsAuthenticating] = useState(false)

  return (
    <div className={cn('flex flex-col gap-6', className)} {...props}>
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
        <div className='flex flex-col gap-6'>
          <Button
            variant='outline'
            type='button'
            className='w-full'
            disabled={isAuthenticating}
            onClick={(e) => {
              e.preventDefault()
              const popupWindow = window.open(
                `https://github.com/login/oauth/authorize?client_id=${process.env.NEXT_PUBLIC_GITHUB_CLIENT_ID}`,
                'GitHub Login',
                'width=600,height=700',
              )
              setIsAuthenticating(true)
              if (popupWindow) {
                const timer = setInterval(() => {
                  if (popupWindow.closed) {
                    setIsAuthenticating(false)
                    clearInterval(timer)
                    routeEntry()
                  }
                }, 100)
              }
            }}
          >
            <Image
              alt='github'
              src='/github-mark.svg'
              className='mr-2 h-4 w-4'
              height={16}
              width={16}
            />
            Login with GitHub
          </Button>
        </div>
      </div>
      <div className='text-muted-foreground text-center text-xs text-balance'>
        By clicking continue, you agree to our{' '}
        <a
          href='/'
          className='text-primary hover:text-primary/80 underline underline-offset-4'
        >
          Terms of Service
        </a>{' '}
        and{' '}
        <a
          href='/'
          className='text-primary hover:text-primary/80 underline underline-offset-4'
        >
          Privacy Policy
        </a>
        .
      </div>
    </div>
  )
}
