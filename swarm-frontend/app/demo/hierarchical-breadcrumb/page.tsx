import { HierarchicalBreadcrumb } from '@/components/ui/hierarchical-breadcrumb'

export default function HierarchicalBreadcrumbDemo() {
  // Example 1: GitHub-style jonator/swarm repository with Next.js project
  const githubStyleItems = [
    {
      label: 'Organizations',
      href: '/orgs',
      children: [
        { label: 'jonator', href: '/jonator', isActive: true },
        { label: 'vercel', href: '/vercel' },
        { label: 'nextjs', href: '/nextjs' },
        { label: 'shadcn', href: '/shadcn' },
        { label: 'tailwindcss', href: '/tailwindcss' },
        { label: 'microsoft', href: '/microsoft' },
        { label: 'google', href: '/google' },
        { label: 'facebook', href: '/facebook' },
      ],
    },
    {
      label: 'Repositories',
      href: '/jonator/repos',
      children: [
        { label: 'swarm', href: '/jonator/swarm', isActive: true },
        { label: 'personal-site', href: '/jonator/personal-site' },
        { label: 'dotfiles', href: '/jonator/dotfiles' },
        { label: 'portfolio', href: '/jonator/portfolio' },
        { label: 'blog', href: '/jonator/blog' },
        { label: 'api-tools', href: '/jonator/api-tools' },
        { label: 'cli-utils', href: '/jonator/cli-utils' },
        { label: 'templates', href: '/jonator/templates' },
      ],
    },
    {
      label: 'Projects',
      href: '/jonator/swarm/projects',
      children: [
        {
          label: 'swarm-frontend (Next.js)',
          href: '/jonator/swarm/swarm-frontend',
          isActive: true,
        },
        {
          label: 'swarm-backend (Elixir)',
          href: '/jonator/swarm/swarm-backend',
        },
        { label: 'swarm-docs', href: '/jonator/swarm/docs' },
        { label: 'swarm-cli', href: '/jonator/swarm/cli' },
        { label: 'swarm-api', href: '/jonator/swarm/api' },
        { label: 'swarm-mobile', href: '/jonator/swarm/mobile' },
        { label: 'swarm-desktop', href: '/jonator/swarm/desktop' },
      ],
    },
  ]

  // Example 2: Teams and Projects (Vercel-style)
  const vercelStyleItems = [
    {
      label: 'Teams',
      href: '/teams',
      children: [
        { label: "Jon Ator's projects", href: '/jonator-team', isActive: true },
        { label: 'Acme Corporation', href: '/acme' },
        { label: 'Design Team', href: '/design-team' },
        { label: 'Engineering Team', href: '/engineering' },
        { label: 'Marketing Team', href: '/marketing' },
        { label: 'Sales Team', href: '/sales' },
        { label: 'Open Source Collective', href: '/oss-collective' },
        { label: 'Startup Incubator', href: '/startup' },
      ],
    },
    {
      label: 'Projects',
      href: '/projects',
      children: [
        { label: 'polaris-web', href: '/polaris-web' },
        { label: 'homepage', href: '/homepage', isActive: true },
        { label: 'blog', href: '/blog' },
        { label: 'docs', href: '/docs' },
        { label: 'api', href: '/api' },
        { label: 'dashboard', href: '/dashboard' },
        { label: 'mobile-app', href: '/mobile' },
        { label: 'landing-page', href: '/landing' },
        { label: 'admin-panel', href: '/admin' },
        { label: 'e-commerce', href: '/ecommerce' },
      ],
    },
    {
      label: 'Environments',
      href: '/environments',
      children: [
        { label: 'Production', href: '/production', isActive: true },
        { label: 'Staging', href: '/staging' },
        { label: 'Preview', href: '/preview' },
        { label: 'Development', href: '/development' },
        { label: 'Testing', href: '/testing' },
      ],
    },
  ]

  // Example 3: Workspace and service types
  const workspaceItems = [
    {
      label: 'Workspaces',
      href: '/workspaces',
      children: [
        { label: 'Personal', href: '/personal', isActive: true },
        { label: 'Team Alpha', href: '/team-alpha' },
        { label: 'Team Beta', href: '/team-beta' },
        { label: 'Enterprise', href: '/enterprise' },
        { label: 'Consultancy', href: '/consultancy' },
        { label: 'Open Source', href: '/opensource' },
        { label: 'Freelance', href: '/freelance' },
        { label: 'Learning', href: '/learning' },
        { label: 'Experiments', href: '/experiments' },
      ],
    },
    {
      label: 'Services',
      href: '/services',
      children: [
        { label: 'Web Application', href: '/webapp', isActive: true },
        { label: 'Mobile App (iOS)', href: '/mobile-ios' },
        { label: 'Mobile App (Android)', href: '/mobile-android' },
        { label: 'API Service', href: '/api' },
        { label: 'Static Site', href: '/static' },
        { label: 'Documentation', href: '/docs' },
        { label: 'E-commerce', href: '/ecommerce' },
        { label: 'Blog', href: '/blog' },
        { label: 'Portfolio', href: '/portfolio' },
        { label: 'Landing Page', href: '/landing' },
      ],
    },
    {
      label: 'Deployments',
      href: '/deployments',
    },
  ]

  return (
    <div className='min-h-screen bg-background p-8 space-y-12'>
      <div className='max-w-6xl mx-auto space-y-8'>
        <div className='space-y-4'>
          <h1 className='text-3xl font-bold text-foreground'>
            Hierarchical Breadcrumb Components
          </h1>
          <p className='text-muted-foreground'>
            Vercel-style hierarchical breadcrumbs with search, create actions,
            and two-level popover navigation
          </p>
        </div>

        <div className='space-y-8'>
          <div className='space-y-4'>
            <h2 className='text-xl font-semibold text-foreground'>
              GitHub Repository Navigation
            </h2>
            <p className='text-sm text-muted-foreground'>
              Navigate through organizations, repositories, and projects like on
              GitHub
            </p>
            <div className='p-6 border border-border rounded-lg bg-card'>
              <HierarchicalBreadcrumb items={githubStyleItems} />
            </div>
          </div>

          <div className='space-y-4'>
            <h2 className='text-xl font-semibold text-foreground'>
              Teams & Projects (Vercel Style)
            </h2>
            <p className='text-sm text-muted-foreground'>
              Search through teams and projects, with create buttons for adding
              new items
            </p>
            <div className='p-6 border border-border rounded-lg bg-card'>
              <HierarchicalBreadcrumb items={vercelStyleItems} />
            </div>
          </div>

          <div className='space-y-4'>
            <h2 className='text-xl font-semibold text-foreground'>
              Workspace & Services
            </h2>
            <p className='text-sm text-muted-foreground'>
              Navigate through workspace hierarchies with searchable service
              types
            </p>
            <div className='p-6 border border-border rounded-lg bg-card'>
              <HierarchicalBreadcrumb items={workspaceItems} />
            </div>
          </div>
        </div>

        <div className='space-y-4'>
          <h2 className='text-xl font-semibold text-foreground'>
            Component Features
          </h2>
          <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
            <div className='p-4 border border-border rounded-lg bg-card'>
              <h3 className='font-medium text-foreground mb-2'>
                Two-Level Display
              </h3>
              <p className='text-sm text-muted-foreground'>
                Shows current level and next level only, keeping the interface
                focused and uncluttered
              </p>
            </div>
            <div className='p-4 border border-border rounded-lg bg-card'>
              <h3 className='font-medium text-foreground mb-2'>Live Search</h3>
              <p className='text-sm text-muted-foreground'>
                Search boxes at the top of each column for instant filtering of
                options
              </p>
            </div>
            <div className='p-4 border border-border rounded-lg bg-card'>
              <h3 className='font-medium text-foreground mb-2'>
                Create Actions
              </h3>
              <p className='text-sm text-muted-foreground'>
                Create buttons at the bottom of each column for adding new items
                to hierarchies
              </p>
            </div>
            <div className='p-4 border border-border rounded-lg bg-card'>
              <h3 className='font-medium text-foreground mb-2'>
                Vercel Design
              </h3>
              <p className='text-sm text-muted-foreground'>
                Matches Vercel's exact UI pattern with seamless button design
                and proper spacing
              </p>
            </div>
          </div>
        </div>

        <div className='space-y-4'>
          <h2 className='text-xl font-semibold text-foreground'>Usage Guide</h2>
          <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
            <div className='space-y-3'>
              <h3 className='font-medium text-foreground'>Navigation</h3>
              <div className='space-y-2 text-sm text-muted-foreground'>
                <div className='flex items-start gap-2'>
                  <span className='font-medium text-foreground min-w-fit'>
                    1.
                  </span>
                  <span>
                    Click breadcrumb button to navigate directly to that level
                  </span>
                </div>
                <div className='flex items-start gap-2'>
                  <span className='font-medium text-foreground min-w-fit'>
                    2.
                  </span>
                  <span>
                    Click chevron (⇅) to open two-level hierarchy popover
                  </span>
                </div>
                <div className='flex items-start gap-2'>
                  <span className='font-medium text-foreground min-w-fit'>
                    3.
                  </span>
                  <span>
                    Navigate between current level and next level options
                  </span>
                </div>
              </div>
            </div>
            <div className='space-y-3'>
              <h3 className='font-medium text-foreground'>Search & Create</h3>
              <div className='space-y-2 text-sm text-muted-foreground'>
                <div className='flex items-start gap-2'>
                  <span className='font-medium text-foreground min-w-fit'>
                    1.
                  </span>
                  <span>Type in search boxes to filter items instantly</span>
                </div>
                <div className='flex items-start gap-2'>
                  <span className='font-medium text-foreground min-w-fit'>
                    2.
                  </span>
                  <span>
                    Click items to navigate or see check marks for active
                    selections
                  </span>
                </div>
                <div className='flex items-start gap-2'>
                  <span className='font-medium text-foreground min-w-fit'>
                    3.
                  </span>
                  <span>
                    Use "Create" buttons to add new items to any level
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className='border border-border rounded-lg p-6 bg-muted/50'>
          <h3 className='font-medium text-foreground mb-2'>Component Import</h3>
          <code className='text-sm text-muted-foreground'>
            import &#123; HierarchicalBreadcrumb &#125; from
            "@/components/ui/hierarchical-breadcrumb"
          </code>
        </div>
      </div>
    </div>
  )
}
