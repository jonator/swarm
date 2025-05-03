'use client'

import { Menu, X } from 'lucide-react'
import Link from 'next/link'
import { useState } from 'react'
import SwarmLogo from './swarm-logo'
import { Button } from './ui/button'

export default function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <header className='fixed top-0 left-0 right-0 z-50 bg-[#0A0A0A]/80 backdrop-blur-md border-b border-[#2A2A2A]/50'>
      <div className='container mx-auto px-4 py-4'>
        <div className='flex items-center justify-between'>
          {/* Logo */}
          <div className='flex items-center'>
            <SwarmLogo size={32} className='mr-2' />
            <span className='text-xl font-bold text-white'>Swarm</span>
          </div>

          {/* Desktop Navigation */}
          <nav className='hidden md:flex items-center space-x-8'>
            <Link
              href='#features'
              className='text-gray-300 hover:text-[#00D4FF] transition-colors'
            >
              Features
            </Link>
            <Link
              href='#how-it-works'
              className='text-gray-300 hover:text-[#00D4FF] transition-colors'
            >
              How It Works
            </Link>
            <Link
              href='#pricing'
              className='text-gray-300 hover:text-[#00D4FF] transition-colors'
            >
              Pricing
            </Link>
            <Link
              href='#'
              className='text-gray-300 hover:text-[#00D4FF] transition-colors'
            >
              Docs
            </Link>
          </nav>

          {/* CTA Button */}
          <div className='hidden md:block'>
            <Button
              asChild
              size='sm'
              className='bg-[#00A3A3] hover:bg-[#00D4FF] text-white transition-all duration-300'
            >
              <Link href='/login'>Sign In</Link>
            </Button>
          </div>

          {/* Mobile Menu Button */}
          <button
            className='md:hidden text-gray-300 hover:text-white'
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className='md:hidden pt-4 pb-2'>
            <nav className='flex flex-col space-y-4'>
              <Link
                href='#features'
                className='text-gray-300 hover:text-[#00D4FF] transition-colors'
                onClick={() => setMobileMenuOpen(false)}
              >
                Features
              </Link>
              <Link
                href='#how-it-works'
                className='text-gray-300 hover:text-[#00D4FF] transition-colors'
                onClick={() => setMobileMenuOpen(false)}
              >
                How It Works
              </Link>
              <Link
                href='#pricing'
                className='text-gray-300 hover:text-[#00D4FF] transition-colors'
                onClick={() => setMobileMenuOpen(false)}
              >
                Pricing
              </Link>
              <Link
                href='#'
                className='text-gray-300 hover:text-[#00D4FF] transition-colors'
                onClick={() => setMobileMenuOpen(false)}
              >
                Docs
              </Link>
              <Button
                size='sm'
                className='bg-[#00A3A3] hover:bg-[#00D4FF] text-white w-full transition-all duration-300'
              >
                Sign In
              </Button>
            </nav>
          </div>
        )}
      </div>
    </header>
  )
}
