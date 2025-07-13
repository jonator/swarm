'use client'

import { usePathname } from 'next/navigation'
import { SkeletonCard } from '@/components/onboarding/loading'

export default function OnboardingLoading() {
  const pathname = usePathname()

  return <SkeletonCard bodyContent={pathname.includes('repo')} />
}
