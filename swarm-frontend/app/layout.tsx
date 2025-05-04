import type { Metadata } from 'next'
import './globals.css'
import { Providers } from '@/components/providers'
import { ThemeProvider as NextThemesProvider } from 'next-themes'
import { Toaster } from 'sonner'

export const metadata: Metadata = {
  title: 'Swarm',
  description: 'Swarm',
  generator: 'v0.dev',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang='en' suppressHydrationWarning>
      <body>
        <NextThemesProvider
          attribute='class'
          defaultTheme='system'
          enableSystem
        >
          <Providers>{children}</Providers>
        </NextThemesProvider>
        <Toaster />
      </body>
    </html>
  )
}
