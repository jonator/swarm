import { cache } from 'react'

// The first component that calls `getNow()` will
// trigger the creation of the Date instance.
// The instance is now bound to the request and will be reused across all subsequent calls to getNow().
export const getNow = cache(() => new Date())
