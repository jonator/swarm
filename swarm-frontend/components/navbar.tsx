'use client'

import { logout } from '@/actions/auth'
import type { User } from '@/lib/services/users'
import { LogOut, Settings } from 'lucide-react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
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
import {
  NavigationMenu,
  NavigationMenuIndicator,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  navigationMenuTriggerStyle,
} from './ui/navigation-menu'

type Tab = {
  label: string
  href: string
}

export default function Navbar({ user, tabs }: { user: User; tabs: Tab[] }) {
  const pathname = usePathname()
  console.log(pathname, tabs)

  return (
    <header className='fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-md border-b border-border/50 px-4 pt-4'>
      <div className='flex items-center justify-between mb-3'>
        {/* Logo */}
        <SwarmLogo size={32} className='mr-2' />

        <div className='flex items-center gap-4'>
          {/* User Avatar Dropdown */}
          <UserDropdown user={user} />
        </div>
      </div>

      {/* Tabs */}
      <NavigationMenu>
        <NavigationMenuList>
          {tabs.map((tab) => (
            <NavigationMenuItem key={tab.href}>
              <NavigationMenuLink
                className={navigationMenuTriggerStyle()}
                asChild
              >
                <Link data-active={pathname === tab.href} href={tab.href}>
                  {tab.label}
                </Link>
              </NavigationMenuLink>
            </NavigationMenuItem>
          ))}
          <NavigationMenuIndicator />
        </NavigationMenuList>
      </NavigationMenu>
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
