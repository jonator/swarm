import { Cpu, GitBranch, Zap } from 'lucide-react'

const features = [
  {
    title: 'Swarm Collaboration',
    description:
      'Multiple AI agents work together to analyze and solve complex issues across your repositories.',
    icon: Cpu,
  },
  {
    title: 'Seamless Integration',
    description:
      'Connect directly to GitHub and Linear for automatic issue tracking and pull request generation.',
    icon: GitBranch,
  },
  {
    title: 'Fast PR Generation',
    description:
      'Receive high-quality, ready-to-merge pull requests in minutes, not hours or days.',
    icon: Zap,
  },
]

export default function Features() {
  return (
    <section className='py-20 px-4 bg-gradient-to-b from-background to-background/80'>
      <div className='container mx-auto max-w-6xl'>
        <div className='grid grid-cols-1 md:grid-cols-3 gap-10'>
          {features.map((feature, index) => (
            <div
              key={index}
              className='flex flex-col items-center text-center p-6 rounded-lg bg-card border border-border hover:border-primary transition-all duration-300'
            >
              <div className='w-16 h-16 flex items-center justify-center rounded-full bg-muted mb-6'>
                <feature.icon className='w-8 h-8 text-primary' />
              </div>
              <h3 className='text-xl font-semibold mb-3 text-foreground'>
                {feature.title}
              </h3>
              <p className='text-muted-foreground'>{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
