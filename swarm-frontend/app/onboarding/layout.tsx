import SwarmLogo from '@/components/swarm-logo'

export default function OnboardingLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <div className='bg-background flex min-h-svh flex-col items-center justify-center gap-6 p-6 md:p-10'>
      <div className='flex flex-col items-center gap-2 animate-in fade-in duration-500'>
        <a
          href='/'
          className='flex flex-col items-center gap-2 font-medium text-foreground'
        >
          <div className='flex size-8 items-center justify-center rounded-md'>
            <SwarmLogo />
          </div>
          <span className='sr-only'>Swarm</span>
        </a>
      </div>
      {children}
    </div>
  )
}
