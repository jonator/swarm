'use client'
import { Computer, Moon, Sun } from 'lucide-react'
import { useTheme } from 'next-themes'

import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { ToggleGroup, ToggleGroupItem } from './ui/toggle-group'

export function ModeToggle() {
  const { setTheme } = useTheme()

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant='ghost'
          size='icon'
          aria-label='Toggle theme'
          className='text-muted-foreground hover:text-foreground'
        >
          <Sun className='h-[1.2rem] w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0' />
          <Moon className='absolute h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100' />
          <span className='sr-only'>Toggle theme</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align='end' className='bg-background border-border'>
        <DropdownMenuItem
          onClick={() => setTheme('light')}
          className='text-foreground hover:bg-muted'
        >
          Light
        </DropdownMenuItem>
        <DropdownMenuItem
          onClick={() => setTheme('dark')}
          className='text-foreground hover:bg-muted'
        >
          Dark
        </DropdownMenuItem>
        <DropdownMenuItem
          onClick={() => setTheme('system')}
          className='text-foreground hover:bg-muted'
        >
          System
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

export function ModeToggleGroup() {
  const { setTheme } = useTheme()

  return (
    <ToggleGroup
      type='single'
      defaultValue='system'
      onValueChange={(value) => value && setTheme(value)}
      className='w-fit'
    >
      <ToggleGroupItem value='light' aria-label='Light theme'>
        <Sun className='h-4 w-4' />
      </ToggleGroupItem>
      <ToggleGroupItem value='dark' aria-label='Dark theme'>
        <Moon className='h-4 w-4' />
      </ToggleGroupItem>
      <ToggleGroupItem value='system' aria-label='System theme'>
        <Computer className='h-4 w-4' />
      </ToggleGroupItem>
    </ToggleGroup>
  )
}
