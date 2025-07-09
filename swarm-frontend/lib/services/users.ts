'use server'

import crypto from 'node:crypto'
import { apiClientWithAuth, authGuard } from '@/lib/client/authed'

/**
 * User data structure returned from the API
 */
export type User = {
  id: number
  email: string
  username: string
  avatar_url: string
}

/**
 * Parameters for fetching user data
 */
export type GetUserParams = {
  id?: number
}

/**
 * Cache configuration for user data
 */
const CACHE_CONFIG = {
  USER_BY_ID: 1, // 1 second for specific user
  CURRENT_USER: 2, // 2 seconds for current user
} as const

/**
 * Fetches user data from the API.
 * 
 * If an ID is provided, fetches a specific user.
 * Otherwise, fetches the current authenticated user.
 * 
 * @param params - Optional parameters including user ID
 * @returns Promise resolving to user data
 */
export async function getUser(params?: GetUserParams): Promise<{ user: User }> {
  if (params?.id) {
    return fetchUserById(params.id)
  }

  return fetchCurrentUser()
}

/**
 * Fetches a specific user by ID
 * 
 * @param userId - The ID of the user to fetch
 * @returns Promise resolving to user data
 */
async function fetchUserById(userId: number): Promise<{ user: User }> {
  return apiClientWithAuth
    .get(`users/${userId}`, {
      next: {
        revalidate: CACHE_CONFIG.USER_BY_ID,
      },
    })
    .json<{ user: User }>()
}

/**
 * Fetches the current authenticated user
 * 
 * Uses token-based cache tagging to ensure proper invalidation
 * when the authentication token changes.
 * 
 * @returns Promise resolving to current user data
 */
async function fetchCurrentUser(): Promise<{ user: User }> {
  const token = await authGuard()
  const tokenHash = generateTokenHash(token!)

  return apiClientWithAuth
    .get('users', {
      next: {
        tags: ['users', tokenHash],
        revalidate: CACHE_CONFIG.CURRENT_USER,
      },
    })
    .json<{ user: User }>()
}

/**
 * Generates a SHA-256 hash of the authentication token
 * 
 * This is used for cache tagging to ensure proper cache invalidation
 * when the user's authentication state changes.
 * 
 * @param token - The authentication token
 * @returns SHA-256 hash of the token
 */
function generateTokenHash(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex')
}