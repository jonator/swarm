import { HierarchicalBreadcrumb } from "@/components/ui/hierarchical-breadcrumb";

export default function HierarchicalBreadcrumbDemo() {
  // Example 1: Vercel-style project breadcrumb
  const vercelStyleItems = [
    {
      label: "Jon Ator's projects",
      children: [
        { label: "Personal Projects", href: "/personal", isActive: true },
        { label: "Work Projects", href: "/work" },
        { label: "Open Source", href: "/oss" },
        { label: "Team Projects", href: "/team" },
      ],
    },
    {
      label: "JA homepage",
      children: [
        { label: "Overview", href: "/overview" },
        { label: "Analytics", href: "/analytics" },
        { label: "Settings", href: "/settings" },
        { label: "Deployments", href: "/deployments", isActive: true },
      ],
    },
    {
      label: "Production",
      href: "/production",
    },
  ];

  // Example 2: Team and workspace navigation
  const teamWorkspaceItems = [
    {
      label: "Acme Corp",
      children: [
        { label: "Engineering", href: "/engineering", isActive: true },
        { label: "Design", href: "/design" },
        { label: "Product", href: "/product" },
        { label: "Marketing", href: "/marketing" },
      ],
    },
    {
      label: "Swarm Project",
      children: [
        { label: "Development", href: "/dev" },
        { label: "Staging", href: "/staging", isActive: true },
        { label: "Production", href: "/prod" },
      ],
    },
    {
      label: "Deployments",
    },
  ];

  // Example 3: File system navigation
  const fileSystemItems = [
    {
      label: "swarm-frontend",
      children: [
        { label: "components", href: "/components", isActive: true },
        { label: "app", href: "/app" },
        { label: "lib", href: "/lib" },
        { label: "public", href: "/public" },
      ],
    },
    {
      label: "ui",
      children: [
        { label: "breadcrumb.tsx", href: "/breadcrumb" },
        { label: "dropdown-menu.tsx", href: "/dropdown" },
        { label: "button.tsx", href: "/button" },
        {
          label: "hierarchical-breadcrumb.tsx",
          href: "/hierarchical",
          isActive: true,
        },
      ],
    },
  ];

  return (
    <div className="min-h-screen bg-background p-8 space-y-12">
      <div className="max-w-4xl mx-auto space-y-8">
        <div className="space-y-4">
          <h1 className="text-3xl font-bold text-foreground">
            Hierarchical Breadcrumb Demo
          </h1>
          <p className="text-muted-foreground">
            Vercel-style hierarchical breadcrumb component with dropdown
            navigation
          </p>
        </div>

        <div className="space-y-8">
          <div className="space-y-4">
            <h2 className="text-xl font-semibold text-foreground">
              Project & Environment Navigation
            </h2>
            <p className="text-sm text-muted-foreground">
              Navigate between projects, environments, and resources like in
              Vercel's dashboard
            </p>
            <div className="p-6 border border-border rounded-lg bg-card">
              <HierarchicalBreadcrumb items={vercelStyleItems} />
            </div>
          </div>

          <div className="space-y-4">
            <h2 className="text-xl font-semibold text-foreground">
              Team & Workspace Navigation
            </h2>
            <p className="text-sm text-muted-foreground">
              Switch between teams, workspaces, and project environments
            </p>
            <div className="p-6 border border-border rounded-lg bg-card">
              <HierarchicalBreadcrumb items={teamWorkspaceItems} />
            </div>
          </div>

          <div className="space-y-4">
            <h2 className="text-xl font-semibold text-foreground">
              File System Navigation
            </h2>
            <p className="text-sm text-muted-foreground">
              Browse through directories and files in a project structure
            </p>
            <div className="p-6 border border-border rounded-lg bg-card">
              <HierarchicalBreadcrumb items={fileSystemItems} />
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <h2 className="text-xl font-semibold text-foreground">Features</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 border border-border rounded-lg bg-card">
              <h3 className="font-medium text-foreground mb-2">
                Dropdown Navigation
              </h3>
              <p className="text-sm text-muted-foreground">
                Click any breadcrumb item with children to see dropdown options
              </p>
            </div>
            <div className="p-4 border border-border rounded-lg bg-card">
              <h3 className="font-medium text-foreground mb-2">
                Active State Indicators
              </h3>
              <p className="text-sm text-muted-foreground">
                Visual indicators show currently active items in dropdowns
              </p>
            </div>
            <div className="p-4 border border-border rounded-lg bg-card">
              <h3 className="font-medium text-foreground mb-2">
                Vercel-style Design
              </h3>
              <p className="text-sm text-muted-foreground">
                Matches Vercel's clean, modern UI with proper spacing and
                typography
              </p>
            </div>
            <div className="p-4 border border-border rounded-lg bg-card">
              <h3 className="font-medium text-foreground mb-2">
                Responsive Layout
              </h3>
              <p className="text-sm text-muted-foreground">
                Adapts to different screen sizes while maintaining usability
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
