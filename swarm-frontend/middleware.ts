import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Get the access token from cookies
  const accessToken = request.cookies.get('access_token')

  // If access token exists and user is trying to access login page, redirect to dashboard
  if (accessToken) {
    // We could verify it against server, but let's assume the token is valid
    // and can redirect inside the dashboard SSR itself if the getUser call returns 5xx or 4xx
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return NextResponse.next()
}

// Configure which paths this middleware will run on
export const config = {
  matcher: ['/login', '/'],
}
