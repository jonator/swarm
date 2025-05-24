'use client'

import { HierarchicalBreadcrumb } from '@/components/ui/hierarchical-breadcrumb'

export default function HierarchicalBreadcrumbDemo() {
  // Example 1: GitHub-style jonator/swarm repository with Next.js project
  const githubStyleItems = [
    {
      label: 'Organizations',
      href: '/orgs',
      children: [
        { label: 'jonator', href: '/jonator' },
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
        { label: 'swarm', href: '/jonator/swarm' },
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
        { label: "Jon Ator's projects", href: '/jonator-team' },
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
        { label: 'homepage', href: '/homepage' },
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
        { label: 'Production', href: '/production' },
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
      label: 'Personal',
      href: '/personal',
      children: [
        {
          label: 'Web Application',
          href: '/personal/webapp',
          children: [
            {
              label: 'React',
              href: '/personal/webapp/react',
              children: [
                {
                  label: 'Create React App',
                  href: '/personal/webapp/react/cra',
                },
                { label: 'Vite', href: '/personal/webapp/react/vite' },
                { label: 'Next.js', href: '/personal/webapp/react/nextjs' }, // /personal/webapp/react/nextjs
                { label: 'Remix', href: '/personal/webapp/react/remix' },
              ],
            },
            {
              label: 'Vue',
              href: '/personal/webapp/vue',
              children: [
                { label: 'Vue CLI', href: '/personal/webapp/vue/cli' },
                { label: 'Nuxt', href: '/personal/webapp/vue/nuxt' },
                { label: 'Vite', href: '/personal/webapp/vue/vite' },
              ],
            },
            {
              label: 'Angular',
              href: '/personal/webapp/angular',
              children: [
                { label: 'Angular CLI', href: '/personal/webapp/angular/cli' },
                { label: 'Ionic', href: '/personal/webapp/angular/ionic' },
              ],
            },
            {
              label: 'Next.js',
              href: '/personal/webapp/nextjs',
              children: [
                {
                  label: 'Pages Router',
                  href: '/personal/webapp/nextjs/pages',
                },
                { label: 'App Router', href: '/personal/webapp/nextjs/app' },
              ],
            },
            {
              label: 'Svelte',
              href: '/personal/webapp/svelte',
              children: [
                { label: 'SvelteKit', href: '/personal/webapp/svelte/kit' },
                { label: 'Vite', href: '/personal/webapp/svelte/vite' },
              ],
            },
          ],
        },
        {
          label: 'Mobile App',
          href: '/personal/mobile',
          children: [
            { label: 'React Native', href: '/personal/mobile/react-native' },
            { label: 'Flutter', href: '/personal/mobile/flutter' },
            { label: 'Swift', href: '/personal/mobile/swift' },
            { label: 'Kotlin', href: '/personal/mobile/kotlin' },
          ],
        },
        {
          label: 'API Service',
          href: '/personal/api',
          children: [
            { label: 'Node.js', href: '/personal/api/nodejs' },
            { label: 'Python', href: '/personal/api/python' },
            { label: 'Go', href: '/personal/api/go' },
            { label: 'Rust', href: '/personal/api/rust' },
          ],
        },
        { label: 'Static Site', href: '/personal/static' },
        { label: 'Documentation', href: '/personal/docs' },
      ],
    },
    {
      label: 'Team Alpha',
      href: '/team-alpha',
      children: [
        {
          label: 'Frontend',
          href: '/team-alpha/frontend',
          children: [
            { label: 'React', href: '/team-alpha/frontend/react' },
            { label: 'TypeScript', href: '/team-alpha/frontend/typescript' },
            { label: 'Tailwind', href: '/team-alpha/frontend/tailwind' },
          ],
        },
        {
          label: 'Backend',
          href: '/team-alpha/backend',
          children: [
            { label: 'Node.js', href: '/team-alpha/backend/nodejs' },
            { label: 'PostgreSQL', href: '/team-alpha/backend/postgresql' },
            { label: 'Redis', href: '/team-alpha/backend/redis' },
          ],
        },
        {
          label: 'DevOps',
          href: '/team-alpha/devops',
          children: [
            { label: 'Docker', href: '/team-alpha/devops/docker' },
            { label: 'AWS', href: '/team-alpha/devops/aws' },
            { label: 'Terraform', href: '/team-alpha/devops/terraform' },
          ],
        },
      ],
    },
    {
      label: 'Enterprise',
      href: '/enterprise',
      children: [
        {
          label: 'Core Services',
          href: '/enterprise/core',
          children: [
            { label: 'Microservices', href: '/enterprise/core/microservices' },
            { label: 'Event Streaming', href: '/enterprise/core/events' },
            { label: 'Authentication', href: '/enterprise/core/auth' },
          ],
        },
        {
          label: 'Infrastructure',
          href: '/enterprise/infra',
          children: [
            { label: 'Kubernetes', href: '/enterprise/infra/k8s' },
            { label: 'Service Mesh', href: '/enterprise/infra/mesh' },
            { label: 'Monitoring', href: '/enterprise/infra/monitoring' },
          ],
        },
        {
          label: 'Security',
          href: '/enterprise/security',
          children: [
            {
              label: 'Identity Management',
              href: '/enterprise/security/identity',
            },
            { label: 'Zero Trust', href: '/enterprise/security/zerotrust' },
            { label: 'Compliance', href: '/enterprise/security/compliance' },
          ],
        },
      ],
    },
    {
      label: 'Open Source',
      href: '/opensource',
      children: [
        {
          label: 'Libraries',
          href: '/opensource/libraries',
          children: [
            { label: 'UI Components', href: '/opensource/libraries/ui' },
            { label: 'Utilities', href: '/opensource/libraries/utils' },
            { label: 'Hooks', href: '/opensource/libraries/hooks' },
          ],
        },
        {
          label: 'Tools',
          href: '/opensource/tools',
          children: [
            { label: 'CLI Tools', href: '/opensource/tools/cli' },
            { label: 'Build Tools', href: '/opensource/tools/build' },
            { label: 'Dev Tools', href: '/opensource/tools/dev' },
          ],
        },
      ],
    },
    {
      label: 'Learning',
      href: '/learning',
      children: [
        {
          label: 'Tutorials',
          href: '/learning/tutorials',
          children: [
            { label: 'React Basics', href: '/learning/tutorials/react' },
            { label: 'TypeScript', href: '/learning/tutorials/typescript' },
            { label: 'Testing', href: '/learning/tutorials/testing' },
          ],
        },
        {
          label: 'Experiments',
          href: '/learning/experiments',
          children: [
            { label: 'WebGL', href: '/learning/experiments/webgl' },
            { label: 'WebAssembly', href: '/learning/experiments/wasm' },
            { label: 'AI/ML', href: '/learning/experiments/ai' },
          ],
        },
      ],
    },
  ]

  // Example usage with your data structure
  const exampleData = [
    {
      label: 'jonator',
      href: '/jonator',
      children: [
        {
          label: '.github',
          href: '/jonator/.github',
        },
        {
          label: 'ACM-Practice',
          href: '/jonator/ACM-Practice',
        },
        {
          label: 'AddressBook',
          href: '/jonator/AddressBook',
        },
        {
          label: 'swarm',
          href: '/jonator/swarm',
        },
        // ... more repositories
      ],
    },
  ]

  // Example with multiple owners/organizations
  const multiOwnerData = [
    {
      label: 'jonator',
      href: '/jonator',
      children: [
        {
          label: 'swarm',
          href: '/jonator/swarm',
        },
        {
          label: 'homepage',
          href: '/jonator/homepage',
        },
      ],
    },
    {
      label: 'acme-corp',
      href: '/acme-corp',
      children: [
        {
          label: 'website',
          href: '/acme-corp/website',
        },
        {
          label: 'api',
          href: '/acme-corp/api',
        },
        {
          label: 'ddd',
          href: '/acme-corp/ddd',
        },
        {
          label: 'aaa',
          href: '/acme-corp/aaa',
        },
      ],
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
              <HierarchicalBreadcrumb
                items={githubStyleItems}
                pathname='/jonator/swarm/swarm-frontend'
                hierarchy={[
                  { label: 'Organizations' },
                  { label: 'Repositories' },
                  { label: 'Projects' },
                ]}
              />
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
              <HierarchicalBreadcrumb
                items={vercelStyleItems}
                pathname='/jonator-team/homepage/production'
                hierarchy={[
                  {
                    label: 'Teams',
                    onCreateClick: () => console.log('Create new team'),
                  },
                  {
                    label: 'Projects',
                    onCreateClick: () => console.log('Create new project'),
                  },
                  {
                    label: 'Environments',
                    onCreateClick: () => console.log('Create new environment'),
                  },
                ]}
              />
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
              <HierarchicalBreadcrumb
                items={workspaceItems}
                pathname='/personal/webapp/react/nextjs'
                hierarchy={[
                  {
                    label: 'Workspaces',
                    onCreateClick: () => console.log('Create new workspace'),
                  },
                  {
                    label: 'Project Types',
                    onCreateClick: () => console.log('Create new project type'),
                  },
                  {
                    label: 'Technologies',
                    onCreateClick: () => console.log('Create new technology'),
                  },
                ]}
              />
            </div>
          </div>
          <div className='space-y-4'>
            <div className='space-y-8 p-8'>
              <div>
                <h3 className='text-lg font-semibold mb-4'>
                  Single Owner Example
                </h3>
                <HierarchicalBreadcrumb
                  items={exampleData}
                  pathname='/jonator/swarm'
                  hierarchy={[
                    {
                      label: 'Owners',
                      onCreateClick: () => console.log('Create new owner'),
                    },
                    {
                      label: 'Repositories',
                      onCreateClick: () => console.log('Create new repository'),
                    },
                  ]}
                />
              </div>

              <div>
                <h3 className='text-lg font-semibold mb-4'>
                  Multiple Owners Example
                </h3>
                <HierarchicalBreadcrumb
                  items={multiOwnerData}
                  pathname='/jonator/swarm'
                  hierarchy={[
                    {
                      label: 'Organizations',
                      onCreateClick: () =>
                        console.log('Create new organization'),
                    },
                    {
                      label: 'Repositories',
                      onCreateClick: () => console.log('Create new repository'),
                    },
                  ]}
                />
              </div>
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
