'use client'

import { getQueryClient } from '@/config/tanstack-query'
import { QueryClientProvider } from '@tanstack/react-query'

export const Providers = ({ children }: { children: React.ReactNode }) => {
  const queryClient = getQueryClient()

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}
