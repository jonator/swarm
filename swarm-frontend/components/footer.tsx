import Link from 'next/link'
import { ModeToggle } from './mode-toggle'

export default function Footer() {
  return (
    <footer className='bg-background'>
      <div className='container mx-auto px-4 py-12'>
        <div className='flex flex-col md:flex-row justify-between items-center'>
          <div className='mb-6 md:mb-0'>
            <h2 className='text-2xl font-bold text-foreground'>Swarm AI</h2>
          </div>

          <nav className='flex items-center gap-8 mb-8 md:mb-0'>
            <ModeToggle />

            <Link
              href='#'
              className='text-muted-foreground hover:text-primary transition-colors'
            >
              Docs
            </Link>
            <Link
              href='#'
              className='text-muted-foreground hover:text-primary transition-colors'
            >
              GitHub
            </Link>
            <Link
              href='#'
              className='text-muted-foreground hover:text-primary transition-colors'
            >
              Contact
            </Link>
          </nav>
        </div>

        <div className='border-t border-border mt-8 pt-8 flex justify-center'>
          <p className='text-muted-foreground text-sm'>Swarm AI © 2025</p>
        </div>
      </div>

      {/* Gradient bar at bottom */}
      <div className='h-1 w-full bg-gradient-to-r from-primary to-primary/80' />
    </footer>
  )
}
