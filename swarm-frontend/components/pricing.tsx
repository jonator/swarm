'use client'

import { Check } from 'lucide-react'
import { useState } from 'react'
import { Button } from './ui/button'

const pricingPlans = [
  {
    name: 'Free',
    price: '$0',
    description: 'Perfect for trying out Swarm AI',
    features: [
      'Up to 3 repositories',
      '10 AI-generated PRs per month',
      'Basic issue analysis',
      'Community support',
    ],
    cta: 'Get Started',
    color: '#00A3A3',
    popular: false,
  },
  {
    name: 'Pro',
    price: '$49',
    period: '/month',
    description: 'For teams and growing projects',
    features: [
      'Up to 10 repositories',
      '100 AI-generated PRs per month',
      'Advanced issue prioritization',
      'Custom AI training',
      'Email support',
      'API access',
    ],
    cta: 'Start Free Trial',
    color: '#00D4FF',
    popular: true,
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    description: 'For large organizations with complex needs',
    features: [
      'Unlimited repositories',
      'Unlimited AI-generated PRs',
      'Custom integrations',
      'Advanced security features',
      'Dedicated account manager',
      'SLA guarantees',
      'On-premise deployment option',
    ],
    cta: 'Contact Sales',
    color: '#4B0082',
    popular: false,
  },
]

export default function Pricing() {
  const [billingPeriod, setBillingPeriod] = useState<'monthly' | 'yearly'>(
    'monthly',
  )

  return (
    <section
      id='pricing'
      className='py-20 px-4 bg-gradient-to-b from-background to-background/80'
    >
      <div className='container mx-auto max-w-6xl'>
        <div className='text-center mb-16'>
          <h2 className='text-3xl md:text-4xl font-bold mb-4'>
            <span className='bg-clip-text text-transparent bg-gradient-to-r from-primary to-primary/80'>
              Simple, Transparent Pricing
            </span>
          </h2>
          <p className='text-muted-foreground max-w-2xl mx-auto'>
            Choose the plan that&apos;s right for your team
          </p>

          {/* Billing toggle */}
          <div className='flex items-center justify-center mt-8'>
            <div className='flex items-center p-1 bg-muted rounded-lg'>
              <button
                className={`px-4 py-2 rounded-md transition-all ${
                  billingPeriod === 'monthly'
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:text-foreground'
                }`}
                onClick={() => setBillingPeriod('monthly')}
              >
                Monthly
              </button>
              <button
                className={`px-4 py-2 rounded-md transition-all ${
                  billingPeriod === 'yearly'
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:text-foreground'
                }`}
                onClick={() => setBillingPeriod('yearly')}
              >
                Yearly <span className='text-xs text-primary'>Save 20%</span>
              </button>
            </div>
          </div>
        </div>

        <div className='grid grid-cols-1 md:grid-cols-3 gap-8'>
          {pricingPlans.map((plan, index) => (
            <div
              key={index}
              className={`relative rounded-lg overflow-hidden transition-all duration-300 ${
                plan.popular
                  ? 'border-2 border-primary transform md:-translate-y-4'
                  : 'border border-border'
              }`}
            >
              {plan.popular && (
                <div className='absolute top-0 right-0 bg-primary text-primary-foreground font-medium py-1 px-4 text-sm'>
                  Most Popular
                </div>
              )}

              <div className='p-8 bg-card h-full flex flex-col'>
                <div className='mb-8'>
                  <h3 className='text-2xl font-bold mb-2 text-foreground'>
                    {plan.name}
                  </h3>
                  <div className='flex items-end mb-2'>
                    <span className='text-4xl font-bold text-primary'>
                      {billingPeriod === 'yearly' &&
                      plan.price !== 'Custom' &&
                      plan.price !== '$0'
                        ? `${plan.price.replace('$', '$')}9`
                        : plan.price}
                    </span>
                    {plan.period && (
                      <span className='text-muted-foreground ml-1'>
                        {billingPeriod === 'yearly' ? '/year' : plan.period}
                      </span>
                    )}
                  </div>
                  <p className='text-muted-foreground'>{plan.description}</p>
                </div>

                <div className='mb-8 flex-grow'>
                  <ul className='space-y-3'>
                    {plan.features.map((feature, i) => (
                      <li key={i} className='flex items-start'>
                        <Check
                          size={18}
                          className='mr-2 mt-0.5 flex-shrink-0 text-primary'
                        />
                        <span className='text-muted-foreground'>{feature}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <Button className='w-full transition-all duration-300 bg-primary hover:bg-primary/90 text-primary-foreground'>
                  {plan.cta}
                </Button>
              </div>
            </div>
          ))}
        </div>

        <div className='mt-16 text-center'>
          <p className='text-muted-foreground'>
            Need a custom solution?{' '}
            <a href='/' className='text-primary hover:underline'>
              Contact our sales team
            </a>
          </p>
        </div>
      </div>
    </section>
  )
}
