'use client'

import { useEffect, useState } from 'react'
import SwarmVisualization from './swarm-visualization'
import { Button } from './ui/button'

export default function Hero() {
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  return (
    <section className='relative flex flex-col items-center justify-center min-h-screen px-4 py-20 overflow-hidden pt-28'>
      <div className='container max-w-5xl mx-auto text-center z-10'>
        <h1 className='text-4xl md:text-6xl font-bold mb-4 text-white tracking-tight leading-tight'>
          <span className='inline-block text-transparent bg-clip-text bg-gradient-to-r from-[#00A3A3] to-[#00D4FF] glow-text'>
            Unleash the Swarm:
          </span>{' '}
          AI-Powered Development
        </h1>
        <p className='text-lg md:text-xl text-gray-300 max-w-3xl mx-auto mb-8'>
          Autonomous agents that solve GitHub and Linear issues with
          precision-crafted pull requests
        </p>
      </div>

      <div className='w-full h-[60vh] my-8 z-0'>
        {mounted && <SwarmVisualization />}
      </div>

      <div className='flex flex-col sm:flex-row gap-4 mt-8 z-10'>
        <Button
          size='lg'
          className='bg-[#00A3A3] hover:bg-[#00D4FF] text-white transition-all duration-300 hover:shadow-[0_0_15px_rgba(0,212,255,0.5)]'
        >
          Get Started
        </Button>
        <Button
          size='lg'
          variant='outline'
          className='border-[#00A3A3] text-[#00A3A3] hover:bg-[#00A3A3] hover:text-white transition-all duration-300'
        >
          Learn More
        </Button>
      </div>
    </section>
  )
}
