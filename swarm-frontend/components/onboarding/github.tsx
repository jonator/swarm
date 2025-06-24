'use client'

import { routeEntry } from '@/actions/routing'
import Image from 'next/image'
import { useState } from 'react'
import { Button } from '../ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../ui/card'

export const InstallGithub = () => {
  const [isInstalling, setIsInstalling] = useState(false)

  return (
    <Card className='w-96'>
      <CardHeader>
        <CardTitle className='flex items-center'>Install GitHub app</CardTitle>
        <CardDescription>
          Grant Swarm access to your GitHub repositories
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
            const popupWindow = window.open(
              `https://github.com/apps/${process.env.NEXT_PUBLIC_GITHUB_APP_NAME}/installations/new`,
              'GitHub Installation',
              'width=600,height=700',
            )
            setIsInstalling(true)
            if (popupWindow) {
              const timer = setInterval(() => {
                if (popupWindow.closed) {
                  setIsInstalling(false)
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
          />{' '}
          Install
        </Button>
      </CardContent>
    </Card>
  )
}
