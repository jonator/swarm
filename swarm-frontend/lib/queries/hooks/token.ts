import { useQuery } from '@tanstack/react-query'
import { temporaryTokenQuery } from '../keys/token'

export const useTemporaryToken = (options?: { enabled?: boolean }) => {
  return useQuery({
    ...temporaryTokenQuery(),
    enabled: options?.enabled ?? true,
  })
}
