'use server'

import { submitEmailOtp } from '@/lib/services/users'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'

export async function submitEmailOtpAction(email: string, code: string) {
  const { token } = await submitEmailOtp(email, code)
  const cookieStore = await cookies()
  cookieStore.set('access_token', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    // Same as JWT token expiration
    maxAge: 60 * 60 * 24 * 7, // 7 days in seconds
  })
  redirect('/dashboard')
}
