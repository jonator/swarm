'use client'

import { useMutation } from '@tanstack/react-query'
import Image from 'next/image'
import { useTheme } from 'next-themes'
import { useEffect, useState } from 'react'
import { toast } from 'sonner'
import { routeEntry } from '@/actions/routing'
import { useLinearOrganization } from '@/lib/queries/hooks/linear'
import { hasLinearAccess, type LinearOrganization } from '@/lib/services/linear'
import { type Repository, updateRepository } from '@/lib/services/repositories'
import { Button } from '../ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../ui/card'
import { Checkbox } from '../ui/checkbox'
import { Label } from '../ui/label'
import { SkeletonCard } from './loading'

export const InstallLinear = ({
  hasAccess,
  repositories,
}: {
  hasAccess: boolean
  repositories: Repository[]
}) => {
  const [isConnected, setIsConnected] = useState(hasAccess)

  const [mounted, setMounted] = useState(false)
  const { resolvedTheme } = useTheme()

  // Query Linear organization when connected
  const { data: organization, isLoading } = useLinearOrganization({
    enabled: isConnected,
  })

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

  if (!isConnected) {
    return (
      <ConnectLinear
        logoSrc={logoSrc}
        onConnected={() => setIsConnected(true)}
      />
    )
  }

  // Show skeleton while loading organization or repositories data
  if (isLoading || !organization) {
    return (
      <div>
              </div>
        <div className='flex items-center w-full justify-center gap-2 mb-4 text-lg font-medium animate-in fade-in'>
          <Image
            alt='linear'
            src={logoSrc}
            className='w-5 h-5'
            height={20}
            width={20}
          />
          <span>Linear Connected</span>
        </div>
              </div>
        <SkeletonCard bodyContent />
      </div>
              </div>
    )
  }

  return (
    <div>
              </div>
      <div className='flex items-center w-full justify-center gap-2 mb-4 text-lg font-medium animate-in fade-in'>
        <Image
          alt='linear'
          src={logoSrc}
          className='w-5 h-5'
          height={20}
          width={20}
        />
        <span>Linear Connected</span>
      </div>
              </div>
      <LinkLinearOrganization
        organization={organization}
        repositories={repositories}
        onDone={() => {
          toast.success('Linear teams linked!', {
            description: 'Your Linear teams have been successfully linked.',
          })
          routeEntry()
        }}
      />
    </div>
              </div>
  )
}

const ConnectLinear = ({
  logoSrc,
  onConnected,
}: {
  logoSrc: string
  onConnected: () => void
}) => {
  const [isInstalling, setIsInstalling] = useState(false)

  const checkLinearAccessMutation = useMutation({
    mutationFn: hasLinearAccess,
    onSuccess: ({ has_access }) => {
      if (has_access) {
        onConnected()
      } else {
        toast.error('Failed to connect to Linear')
      }
    },
    onError: (error) => {
      console.error(error.message)
      toast.error('Failed to connect to Linear')
    },
  })

  const handleConnect = async () => {
    const { has_access } = await hasLinearAccess()
    if (has_access) {
      onConnected()
      return
    }

    const redirectUri = `${window.location.origin}/auth/linear/callback`
    const url = new URL('https://linear.app/oauth/authorize')
    const state = Math.random().toString(36).substring(2, 15)
    localStorage.setItem('linear_auth_state', state)
    url.searchParams.set('client_id', process.env.NEXT_PUBLIC_LINEAR_CLIENT_ID!)
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
  }

  return (
    <Card className='w-96'>
      <CardHeader>
        <CardTitle className='flex items-center'>Connect Linear</CardTitle>
        <CardDescription>
          Grant Swarm access to your Linear workspace
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className='space-y-2'>
          <Button
            variant='outline'
            type='button'
            className='w-full'
            disabled={isInstalling}
            onClick={(e) => {
              e.preventDefault()
              handleConnect()
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
          <Button
            type='button'
            variant='link'
            className='w-full'
            onClick={() => routeEntry()}
          >
            Skip
          </Button>
        </div>
              </div>
      </CardContent>
    </Card>
  )
}

const LinkLinearOrganization = ({
  organization,
  repositories,
  onDone,
}: {
  organization: LinearOrganization
  repositories: Repository[]
  onDone: () => void
}) => {
  const [selectedTeams, setSelectedTeams] = useState<string[]>(() => {
    return organization?.teams?.nodes?.length
      ? [organization.teams.nodes[0].id]
      : []
  })

  const handleTeamToggle = (teamId: string, checked: boolean) => {
    if (checked) {
      setSelectedTeams((prev) => [...prev, teamId])
    } else {
      setSelectedTeams((prev) => prev.filter((id) => id !== teamId))
    }
  }

  const handleContinue = async () => {
    await updateRepository({
      id: repositories[0].id,
      linear_team_external_ids: selectedTeams,
    })
    onDone()
  }

  return (
    <Card className='w-96'>
      <CardHeader>
        <CardTitle className='flex items-center'>
          Link Teams & Repository
        </CardTitle>
        <CardDescription>
          Select Linear teams to link with your repository for agent access
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className='space-y-4'>
          {/* Repository Display (hardcoded first repository) */}
          {repositories.length > 0 && (
            <div className='space-y-3'>
              <div className='text-sm font-medium'>Repository</div>
              </div>
              <div className='p-3 bg-muted rounded-md border'>
                <div className='flex items-center text-sm'>
                  <span className='text-muted-foreground'>
                    {repositories[0].owner}
                  </span>
                  <span className='mx-1'>/</span>
                  <span className='font-medium'>{repositories[0].name}</span>
                </div>
              </div>
              </div>
              </div>
            </div>
              </div>
          )}

          {/* Team Selection */}
          {organization?.teams.nodes.length ? (
            <div className='space-y-3'>
              <div className='text-sm font-medium'>
                Teams ({organization.teams.nodes.length})
              </div>
              </div>
              {organization.teams.nodes.map((team) => (
                <div key={team.id} className='flex items-center space-x-2'>
                  <Checkbox
                    id={team.id}
                    checked={selectedTeams.includes(team.id)}
                    onCheckedChange={(checked) =>
                      handleTeamToggle(team.id, !!checked)
                    }
                  />
                  <Label
                    htmlFor={team.id}
                    className='text-sm cursor-pointer flex-1'
                  >
                    {team.name}
                  </Label>
                </div>
              </div>
              ))}
              <div className='text-xs text-muted-foreground'>
                {selectedTeams.length > 0
                  ? `${selectedTeams.length} team${selectedTeams.length !== 1 ? 's' : ''} selected`
                  : 'Select at least one team to continue'}
              </div>
              </div>
            </div>
              </div>
          ) : (
            <div className='text-sm text-muted-foreground'>
              No teams found in your Linear workspace
            </div>
              </div>
          )}

          <div className='space-y-2'>
            <Button
              type='button'
              className='w-full'
              onClick={handleContinue}
              disabled={selectedTeams.length === 0}
            >
              {selectedTeams.length > 0
                ? 'Link Teams & Repository'
                : 'Select at least one team'}
            </Button>
          </div>
              </div>
        </div>
              </div>
      </CardContent>
    </Card>
  )
}
