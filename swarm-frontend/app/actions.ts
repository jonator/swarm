'use server'

import { submitEmailOtp } from '@/lib/services/users'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'

export async function submitEmailOtpAction(email: string, code: string) {
  const data = await submitEmailOtp(email, code)
  const cookieStore = await cookies()
  cookieStore.set('access_token', data.token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
  })
  redirect('/dashboard')
}
