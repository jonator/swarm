'use client'

import { useState } from 'react'
import { cn } from '../lib/utils'
import SwarmLogo from './swarm-logo'
import { Button } from './ui/button'
import { Input } from './ui/input'
import { Label } from './ui/label'

export function LoginForm({
  className,
  ...props
}: React.ComponentProps<'div'>) {
  const [email, setEmail] = useState('')

  return (
    <div className={cn('flex flex-col gap-6', className)} {...props}>
      <form>
        <div className='flex flex-col gap-6'>
          <div className='flex flex-col items-center gap-2'>
            <a
              href='#'
              className='flex flex-col items-center gap-2 font-medium text-foreground'
            >
              <div className='flex size-8 items-center justify-center rounded-md bg-primary/10'>
                <SwarmLogo />
              </div>
              <span className='sr-only'>Swarm</span>
            </a>
            <h1 className='text-xl font-bold text-foreground'>
              Welcome to Swarm
            </h1>
          </div>
          <div className='flex flex-col gap-6'>
            <div className='grid gap-3'>
              <Label htmlFor='email' className='text-foreground'>
                Email
              </Label>
              <Input
                id='email'
                type='email'
                placeholder='me@example.com'
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className='bg-background text-foreground border-input'
              />
            </div>
            <Button type='submit' className='w-full'>
              Send Login Code
            </Button>
          </div>
        </div>
      </form>
      <div className='text-muted-foreground text-center text-xs text-balance'>
        By clicking continue, you agree to our{' '}
        <a
          href='#'
          className='text-primary hover:text-primary/80 underline underline-offset-4'
        >
          Terms of Service
        </a>{' '}
        and{' '}
        <a
          href='#'
          className='text-primary hover:text-primary/80 underline underline-offset-4'
        >
          Privacy Policy
        </a>
        .
      </div>
    </div>
  )
}
