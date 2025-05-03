import { Cpu, GitBranch, Zap } from "lucide-react"

const features = [
  {
    title: "Swarm Collaboration",
    description: "Multiple AI agents work together to analyze and solve complex issues across your repositories.",
    icon: Cpu,
  },
  {
    title: "Seamless Integration",
    description: "Connect directly to GitHub and Linear for automatic issue tracking and pull request generation.",
    icon: GitBranch,
  },
  {
    title: "Fast PR Generation",
    description: "Receive high-quality, ready-to-merge pull requests in minutes, not hours or days.",
    icon: Zap,
  },
]

export default function Features() {
  return (
    <section className="py-20 px-4 bg-gradient-to-b from-[#0A0A0A] to-[#1A1A1A]">
      <div className="container mx-auto max-w-6xl">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-10">
          {features.map((feature, index) => (
            <div
              key={index}
              className="flex flex-col items-center text-center p-6 rounded-lg bg-[#121212] border border-[#2A2A2A] hover:border-[#00A3A3] transition-all duration-300"
            >
              <div className="w-16 h-16 flex items-center justify-center rounded-full bg-[#1A1A1A] mb-6">
                <feature.icon className="w-8 h-8 text-[#00D4FF]" />
              </div>
              <h3 className="text-xl font-semibold mb-3 text-white">{feature.title}</h3>
              <p className="text-gray-400">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
