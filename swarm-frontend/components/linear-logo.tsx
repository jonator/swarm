'use client'

import { useTheme } from 'next-themes'
import Image from 'next/image'
import { useEffect, useState } from 'react'

export const LinearLogo = ({ className }: { className?: string }) => {
  const [mounted, setMounted] = useState(false)
  const { resolvedTheme } = useTheme()

  useEffect(() => {
    setMounted(true)
  }, [])

  const logoSrc = mounted
    ? resolvedTheme === 'dark'
      ? '/linear-light-logo.svg'
      : '/linear-dark-logo.svg'
    : '/linear-dark-logo.svg'

  return (
    <Image
      src={logoSrc}
      alt='Linear'
      className={className}
      width={16}
      height={16}
    />
  )
}
