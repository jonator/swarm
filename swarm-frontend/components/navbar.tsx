'use client'

import { logout } from '@/actions/auth'
import type { User } from '@/lib/services/users'
import { LogOut, Settings, User as UserIcon } from 'lucide-react'
import { ModeToggleGroup } from './mode'
import SwarmLogo from './swarm-logo'
import { Avatar, AvatarFallback, AvatarImage } from './ui/avatar'
import { Button } from './ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from './ui/dropdown-menu'

export default function Navbar({ user }: { user: User }) {
  return (
    <header className='fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-md border-b border-border/50 px-4 py-4'>
      <div className='flex items-center justify-between'>
        {/* Logo */}
        <SwarmLogo size={32} className='mr-2' />

        <div className='flex items-center gap-4'>
          {/* User Avatar Dropdown */}
          <UserDropdown user={user} />
        </div>
      </div>
    </header>
  )
}

const UserDropdown = ({ user }: { user: User }) => (
  <DropdownMenu>
    <DropdownMenuTrigger asChild>
      <Button variant='ghost' className='relative size-8 rounded-full'>
        <Avatar className='size-8'>
          <AvatarImage
            src={user.avatar_url}
            alt={user.username || 'User avatar'}
          />
          <AvatarFallback>
            {user.username?.[0]?.toUpperCase() || 'U'}
          </AvatarFallback>
        </Avatar>
      </Button>
    </DropdownMenuTrigger>
    <DropdownMenuContent className='w-56' align='end' forceMount>
      <DropdownMenuLabel className='font-normal'>
        <div className='flex flex-col space-y-1'>
          <p className='text-sm font-medium leading-none'>{user.username}</p>
          <p className='text-xs leading-none text-muted-foreground'>
            {user.email}
          </p>
        </div>
      </DropdownMenuLabel>
      <DropdownMenuSeparator />
      <DropdownMenuLabel>
        <ModeToggleGroup />
      </DropdownMenuLabel>
      <DropdownMenuSeparator />
      <DropdownMenuGroup>
        <DropdownMenuItem>
          <UserIcon className='mr-2 size-4' />
          <span>Profile</span>
        </DropdownMenuItem>
        <DropdownMenuItem>
          <Settings className='mr-2 size-4' />
          <span>Settings</span>
        </DropdownMenuItem>
      </DropdownMenuGroup>
      <DropdownMenuSeparator />
      <DropdownMenuItem onClick={() => logout()}>
        <LogOut className='mr-2 size-4' />
        <span>Log out</span>
      </DropdownMenuItem>
    </DropdownMenuContent>
  </DropdownMenu>
)
