import { CheckCircle, GitBranch, GitPullRequest } from 'lucide-react'

const steps = [
  {
    number: '01',
    title: 'Connect GitHub and Linear',
    description:
      'Seamlessly integrate your repositories and issue tracking with a few clicks.',
    icon: GitBranch,
    color: '#00A3A3',
  },
  {
    number: '02',
    title: 'Assign Issues',
    description:
      'Tag issues for AI resolution and let the swarm analyze and prioritize them.',
    icon: CheckCircle,
    color: '#00D4FF',
  },
  {
    number: '03',
    title: 'Review the PR',
    description:
      'Receive precision-crafted pull requests ready for your review and approval.',
    icon: GitPullRequest,
    color: '#4B0082',
  },
]

export default function Steps() {
  return (
    <section id='how-it-works' className='py-20 px-4 bg-background'>
      <div className='container mx-auto max-w-6xl'>
        <div className='text-center mb-16'>
          <h2 className='text-3xl md:text-4xl font-bold mb-4'>
            <span className='bg-clip-text text-transparent bg-gradient-to-r from-primary to-primary/80'>
              How It Works
            </span>
          </h2>
          <p className='text-muted-foreground max-w-2xl mx-auto'>
            Get started in minutes with our simple three-step process
          </p>
        </div>

        <div className='grid grid-cols-1 md:grid-cols-3 gap-8'>
          {steps.map((step, index) => (
            <div
              key={index}
              className='relative p-8 rounded-lg bg-card border border-border hover:border-primary transition-all duration-300 group'
            >
              {/* Step number */}
              <div className='absolute -top-5 -left-5 w-10 h-10 rounded-full flex items-center justify-center text-primary-foreground font-bold bg-primary'>
                {step.number}
              </div>

              {/* Icon */}
              <div className='w-16 h-16 flex items-center justify-center rounded-full bg-muted mb-6 group-hover:bg-primary/10 transition-all duration-300'>
                <step.icon className='w-8 h-8 text-primary' />
              </div>

              {/* Content */}
              <h3 className='text-xl font-semibold mb-3 text-foreground'>
                {step.title}
              </h3>
              <p className='text-muted-foreground'>{step.description}</p>

              {/* Connector line for desktop */}
              {index < steps.length - 1 && (
                <div className='hidden md:block absolute top-1/2 -right-4 w-8 h-0.5 bg-gradient-to-r from-primary to-primary/80' />
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
