import type { Metadata } from 'next'
import './globals.css'
import { ThemeProvider as NextThemesProvider } from 'next-themes'

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
    <html lang='en'>
      <body>
        <NextThemesProvider
          attribute='class'
          defaultTheme='system'
          enableSystem
        >
          {children}
        </NextThemesProvider>
      </body>
    </html>
  )
}
