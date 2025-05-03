import Header from "@/components/header"
import Hero from "@/components/hero"
import Steps from "@/components/steps"
import Features from "@/components/features"
import Pricing from "@/components/pricing"
import Footer from "@/components/footer"

export default function Home() {
  return (
    <main className="min-h-screen bg-[#0A0A0A] text-white overflow-hidden">
      <Header />
      <Hero />
      <Steps />
      <Features />
      <Pricing />
      <Footer />
    </main>
  )
}
