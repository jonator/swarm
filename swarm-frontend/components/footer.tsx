import Link from 'next/link'

export default function Footer() {
  return (
    <footer className='bg-[#0A0A0A]'>
      <div className='container mx-auto px-4 py-12'>
        <div className='flex flex-col md:flex-row justify-between items-center'>
          <div className='mb-6 md:mb-0'>
            <h2 className='text-2xl font-bold text-white'>Swarm AI</h2>
          </div>

          <nav className='flex gap-8 mb-8 md:mb-0'>
            <Link
              href='#'
              className='text-gray-400 hover:text-[#00D4FF] transition-colors'
            >
              Docs
            </Link>
            <Link
              href='#'
              className='text-gray-400 hover:text-[#00D4FF] transition-colors'
            >
              GitHub
            </Link>
            <Link
              href='#'
              className='text-gray-400 hover:text-[#00D4FF] transition-colors'
            >
              Contact
            </Link>
          </nav>
        </div>

        <div className='border-t border-[#2A2A2A] mt-8 pt-8 flex justify-center'>
          <p className='text-gray-500 text-sm'>Swarm AI © 2025</p>
        </div>
      </div>

      {/* Gradient bar at bottom */}
      <div className='h-1 w-full bg-gradient-to-r from-[#00A3A3] to-[#4B0082]'></div>
    </footer>
  )
}
