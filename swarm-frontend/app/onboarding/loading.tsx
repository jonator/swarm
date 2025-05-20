'use client'

import { SkeletonCard } from '@/components/onboarding/loading'
import { usePathname } from 'next/navigation'

export default function OnboardingLoading() {
  const pathname = usePathname()

  return <SkeletonCard bodyContent={pathname.includes('repo')} />
}
