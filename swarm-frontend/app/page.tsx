import Features from '../components/features'
import Footer from '../components/footer'
import Header from '../components/header'
import Hero from '../components/hero'
import Pricing from '../components/pricing'
import Steps from '../components/steps'

export default function Home() {
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
