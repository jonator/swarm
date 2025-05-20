import Features from './features'
import Footer from './footer'
import Header from './header'
import Hero from './hero'
import Pricing from './pricing'
import Steps from './steps'

export function Home() {
  return (
    <main className='min-h-screen bg-background text-white overflow-hidden'>
      <Header />
      <Hero />
      <Steps />
      <Features />
      <Pricing />
      <Footer />
    </main>
  )
}
