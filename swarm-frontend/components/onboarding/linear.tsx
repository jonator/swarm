'use client'

import Image from 'next/image'
import { useState, useEffect } from 'react'
import { useTheme } from 'next-themes'
import { useMutation } from '@tanstack/react-query'
import { Button } from '../ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../ui/card'
import { routeEntry } from '@/actions/routing'
import { hasLinearAccess } from '@/lib/services/linear'
import { toast } from 'sonner'

export const InstallLinear = () => {
  const [isInstalling, setIsInstalling] = useState(false)
  const [mounted, setMounted] = useState(false)
  const { resolvedTheme } = useTheme()

  // Handle hydration
  useEffect(() => {
    setMounted(true)
  }, [])

  // Use a default logo until mounted, then use theme-based logo
  const logoSrc = mounted
    ? resolvedTheme === 'dark'
      ? '/linear-light-logo.svg'
      : '/linear-dark-logo.svg'
    : '/linear-dark-logo.svg' // Default fallback

  const checkLinearAccessMutation = useMutation({
    mutationFn: hasLinearAccess,
    onSuccess: ({ has_access }) => {
      if (has_access) {
        routeEntry()
      } else {
        toast.error('Failed to connect to Linear')
      }
    },
    onError: (error) => {
      console.error(error.message)
      toast.error('Failed to connect to Linear')
    },
  })

  return (
    <Card className='w-96'>
      <CardHeader>
        <CardTitle className='flex items-center'>Connect Linear</CardTitle>
        <CardDescription>
          Grant Swarm access to your Linear workspace
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Button
          variant='outline'
          type='button'
          className='w-full'
          disabled={isInstalling}
          onClick={(e) => {
            e.preventDefault()
            const redirectUri = `${window.location.origin}/auth/linear/callback`
            const url = new URL('https://linear.app/oauth/authorize')
            const state = Math.random().toString(36).substring(2, 15)
            localStorage.setItem('linear_auth_state', state)
            url.searchParams.set(
              'client_id',
              process.env.NEXT_PUBLIC_LINEAR_CLIENT_ID!,
            )
            url.searchParams.set('response_type', 'code')
            url.searchParams.set(
              'scope',
              'read,write,comments:create,app:assignable,app:mentionable',
            )
            url.searchParams.set('redirect_uri', redirectUri)
            url.searchParams.set('actor', 'app')
            url.searchParams.set('state', state)
            url.searchParams.set('prompt', 'consent')
            const popupWindow = window.open(
              url.toString(),
              'Linear Authorization',
              'width=600,height=700',
            )
            setIsInstalling(true)
            if (popupWindow) {
              const timer = setInterval(() => {
                if (popupWindow.closed) {
                  setIsInstalling(false)
                  clearInterval(timer)
                  checkLinearAccessMutation.mutate()
                }
              }, 100)
            }
          }}
        >
          <Image
            alt='linear'
            src={logoSrc}
            className='mr-2 h-4 w-4'
            height={16}
            width={16}
          />{' '}
          Connect
        </Button>
        <div className='mt-2 text-center'>
          <Button
            variant='link'
            size='sm'
            type='button'
            className='text-muted-foreground hover:text-foreground'
            onClick={() => routeEntry()}
          >
            Skip
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
