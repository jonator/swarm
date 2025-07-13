import { isServer, QueryClient } from '@tanstack/react-query'

let browserQueryClient: QueryClient | undefined

/*
 * This section is reserved for initializing the browserQueryClient
 * and setting up the localStoragePersister for persisting the query client.
 * New query clients are created on the server.
 */
export const getQueryClient = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        // Disabling for now as data structures are subject to change frequently
        // Can re-enable once we have a stable data structure / spec
        // Reduces complexity of iterating quickly
        // gcTime: 1000 * 60 * 60 * 24, // 24 hours

        // With SSR, we usually want to set some default staleTime
        // above 0 to avoid refetching immediately on the client
        staleTime: 60 * 1000,
      },
    },
  })

  if (isServer) {
    // Server: always make a new query client. This ensures that data is not shared between different users and requests.
    return queryClient
  }

  // Browser: make a new query client if we don't already have one
  // This is very important, so we don't re-make a new client if React
  // suspends during the initial render. This may not be needed if we
  // have a suspense boundary BELOW the creation of the query client
  if (!browserQueryClient) browserQueryClient = queryClient

  // this stuff was causing issues with SSR
  // where RSC was hydrating data properly
  // but the query client on browser was returning
  // stale data only on initial load
  // may be able to get it working by tweaking hydrateOptions and dehydrateOptions
  // in persistQueryClient

  // see
  // https://tanstack.com/query/latest/docs/framework/react/plugins/persistQueryClient#persistqueryclient

  // const localStoragePersister = createSyncStoragePersister({
  //   storage: typeof window !== 'undefined' ? window.localStorage : undefined,
  // })

  // persistQueryClient({
  //   queryClient: browserQueryClient,
  //   persister: localStoragePersister,
  // })

  return browserQueryClient
}
