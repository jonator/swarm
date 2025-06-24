'use client'

import { Check, ChevronsUpDown, CirclePlus, Search, Slash } from 'lucide-react'
import Link from 'next/link'
import * as React from 'react'

import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from '@/components/ui/breadcrumb'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'
import { cn } from '@/lib/utils/shadcn'
import { useMemo } from 'react'

export interface HierarchicalItem {
  label: string
  href: string
  children?: HierarchicalItem[]
}

export interface HierarchyLevel {
  label: string
  onCreateClick?: () => void
  createCta?: string
}

interface HierarchicalBreadcrumbProps {
  items: HierarchicalItem[]
  pathname: string
  hierarchy: HierarchyLevel[]
  className?: string
}

function HierarchicalBreadcrumbPopover({
  selectedItemLabel,
  items,
  pathname,
  hierarchy,
}: {
  selectedItemLabel: string
  items: HierarchicalItem[]
  pathname: string
  hierarchy: HierarchyLevel[]
}) {
  const [searchTerm, setSearchTerm] = React.useState('')
  const [parentSearchTerm, setParentSearchTerm] = React.useState('')
  const [hoveredParent, setHoveredParent] = React.useState<string | null>(null)
  const [open, setOpen] = React.useState(false)

  // Parse pathname to determine active states
  const pathSegments = pathname.split('/').filter(Boolean)
  const currentParent = pathSegments[0] || ''
  const currentChild = pathSegments[1] || ''

  const selectedItem = items.find((item) => item.label === selectedItemLabel)

  // For the parent level, we want to show:
  // 1. A column for selecting different parents (always show, even with single parent)
  // 2. A column for the children under the current parent or hovered parent
  const targetParent = hoveredParent || currentParent
  const targetParentItem = items.find((item) => item.label === targetParent)
  const children = targetParentItem?.children || selectedItem?.children || []

  // Get hierarchy labels and callbacks
  const parentLevel = hierarchy[0]
  const childLevel = hierarchy[1]

  // Filter parents based on search term
  const filteredParents = items.filter((parent) =>
    parent.label.toLowerCase().includes(parentSearchTerm.toLowerCase()),
  )

  // Filter children based on search term
  const filteredChildren = children.filter((child) =>
    child.label.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant='ghost'
          size='sm'
          className={cn(
            'flex items-center justify-center px-1 py-1.5 transition-colors',
            'hover:bg-accent hover:text-accent-foreground',
            'text-muted-foreground hover:text-foreground',
            'h-auto',
          )}
        >
          <ChevronsUpDown className='h-3.5 w-3.5' />
        </Button>
      </PopoverTrigger>
      <PopoverContent className='p-3 w-fit' align='start' sideOffset={8}>
        <div className='flex gap-3'>
          {/* Parents column (always show to allow creating new parents) */}
          <div className='space-y-3 w-52'>
            <div className='space-y-2'>
              <h4 className='text-xs font-medium text-muted-foreground uppercase tracking-wider truncate'>
                {parentLevel.label}
              </h4>

              {/* Search box for parents */}
              <div className='relative'>
                <Search className='absolute left-2 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground' />
                <Input
                  placeholder={`Search ${parentLevel.label.toLowerCase()}...`}
                  value={parentSearchTerm}
                  onChange={(e) => setParentSearchTerm(e.target.value)}
                  className='pl-8 h-8 text-sm'
                />
              </div>
            </div>

            <div className='space-y-0'>
              <div className='space-y-0.5 max-h-64 overflow-y-auto'>
                {filteredParents.map((parent, parentIndex) => (
                  <Button
                    key={`${parent.label}-${parentIndex}`}
                    variant='ghost'
                    size='sm'
                    className={cn(
                      'w-full justify-between px-2 py-1.5 h-auto text-sm font-normal',
                      'hover:bg-accent/50 focus:bg-accent/50',
                      parent.label === currentParent &&
                        'bg-accent text-accent-foreground',
                      'transition-colors',
                    )}
                    asChild
                    onMouseEnter={() => setHoveredParent(parent.label)}
                    onMouseLeave={() => setHoveredParent(null)}
                  >
                    <Link href={parent.href}>
                      <span className='truncate'>{parent.label}</span>
                      {parent.label === currentParent && (
                        <Check className='h-3.5 w-3.5 text-primary flex-shrink-0' />
                      )}
                    </Link>
                  </Button>
                ))}

                {filteredParents.length === 0 && parentSearchTerm && (
                  <div className='px-2 py-4 text-sm text-muted-foreground text-center'>
                    No {parentLevel.label.toLowerCase()} found
                  </div>
                )}
              </div>

              {/* Create parent button */}
              {parentLevel.onCreateClick && (
                <Button
                  variant='ghost'
                  size='sm'
                  className={cn(
                    'w-full justify-start px-2 py-1.5 h-auto text-sm font-normal',
                    'text-muted-foreground hover:text-foreground',
                    'border-t border-border/50 rounded-none rounded-b-sm pt-2',
                  )}
                  onClick={() => {
                    parentLevel.onCreateClick?.()
                    setOpen(false)
                  }}
                >
                  <CirclePlus className='h-3.5 w-3.5 mr-2 flex-shrink-0' />
                  <span className='truncate'>
                    {parentLevel.createCta ||
                      `Create ${parentLevel.label.slice(0, -1)}`}
                  </span>
                </Button>
              )}
            </div>
          </div>

          {/* Children column */}
          {children.length > 0 && (
            <div className='space-y-3 w-52'>
              <div className='space-y-2'>
                <h4 className='text-xs font-medium text-muted-foreground uppercase tracking-wider truncate'>
                  {childLevel.label}
                  {hoveredParent && hoveredParent !== currentParent && (
                    <span className='text-xs normal-case ml-1 text-muted-foreground/70'>
                      for {hoveredParent}
                    </span>
                  )}
                </h4>

                {/* Search box */}
                <div className='relative'>
                  <Search className='absolute left-2 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground' />
                  <Input
                    placeholder={`Search ${childLevel.label.toLowerCase()}...`}
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className='pl-8 h-8 text-sm'
                  />
                </div>
              </div>

              <div className='space-y-0'>
                {/* Child list */}
                <div className='space-y-0.5 max-h-64 overflow-y-auto'>
                  {filteredChildren.map((child, childIndex) => (
                    <Button
                      key={`${child.label}-${childIndex}`}
                      variant='ghost'
                      size='sm'
                      className={cn(
                        'w-full justify-between px-2 py-1.5 h-auto text-sm font-normal',
                        'hover:bg-accent/50 focus:bg-accent/50',
                        child.label === currentChild &&
                          'bg-accent text-accent-foreground',
                        'transition-colors',
                      )}
                      asChild
                    >
                      <Link href={child.href}>
                        <span className='truncate'>{child.label}</span>
                        {child.label === currentChild && (
                          <Check className='h-3.5 w-3.5 text-primary flex-shrink-0' />
                        )}
                      </Link>
                    </Button>
                  ))}

                  {filteredChildren.length === 0 && searchTerm && (
                    <div className='px-2 py-4 text-sm text-muted-foreground text-center'>
                      No {childLevel.label.toLowerCase()} found
                    </div>
                  )}
                </div>

                {/* Create child button */}
                {childLevel?.onCreateClick && (
                  <Button
                    variant='ghost'
                    size='sm'
                    className={cn(
                      'w-full justify-start px-2 py-1.5 h-auto text-sm font-normal',
                      'text-muted-foreground hover:text-foreground',
                      'border-t border-border/50 rounded-none rounded-b-sm pt-2',
                    )}
                    onClick={() => {
                      childLevel.onCreateClick?.()
                      setOpen(false)
                    }}
                  >
                    <CirclePlus className='h-3.5 w-3.5 mr-2 flex-shrink-0' />
                    <span className='truncate'>
                      {childLevel.createCta ||
                        `Create ${childLevel.label.slice(0, -1)}`}
                    </span>
                  </Button>
                )}
              </div>
            </div>
          )}
        </div>
      </PopoverContent>
    </Popover>
  )
}

export function HierarchicalBreadcrumb({
  items,
  pathname,
  hierarchy,
  className,
}: HierarchicalBreadcrumbProps) {
  const pathSegments = pathname.split('/').filter(Boolean)

  // Parse pathname to build breadcrumb path recursively
  const breadcrumbPath = useMemo(() => {
    const path: HierarchicalItem[] = []

    // Helper function to recursively find items in the hierarchy
    const findPath = (
      items: HierarchicalItem[],
      segments: string[],
      currentIndex: number = 0,
    ) => {
      if (currentIndex >= segments.length) return true

      const currentSegment = segments[currentIndex]
      const currentItem = items.find((item) => item.label === currentSegment)

      if (!currentItem) return false

      path.push(currentItem)

      if (currentItem.children && currentIndex < segments.length - 1) {
        return findPath(currentItem.children, segments, currentIndex + 1)
      }

      return true
    }

    // Start recursive search from root items
    findPath(items, pathSegments)

    // If no path was found, return root items
    return path.length > 0 ? path : items
  }, [items, pathSegments])

  return (
    <Breadcrumb className={className}>
      <BreadcrumbList className='flex items-center gap-1'>
        {breadcrumbPath.map((item, index) => {
          const isLast = index === breadcrumbPath.length - 1
          const isFirst = index === 0

          return (
            <React.Fragment key={`${item.label}-${index}`}>
              <BreadcrumbItem>
                {isLast && !isFirst ? (
                  // Show child as final breadcrumb page
                  <BreadcrumbPage
                    className={cn(
                      'flex items-center gap-1.5 rounded-md text-sm font-medium',
                      'text-foreground',
                    )}
                  >
                    {item.label}
                  </BreadcrumbPage>
                ) : (
                  <div className='flex items-center gap-1'>
                    {pathSegments.length === 1 ? (
                      <BreadcrumbPage
                        className={cn(
                          'flex items-center gap-1.5 rounded-md text-sm font-medium',
                          'text-foreground',
                        )}
                      >
                        {item.label}
                      </BreadcrumbPage>
                    ) : (
                      <BreadcrumbLink href={item.href}>
                        {item.label}
                      </BreadcrumbLink>
                    )}

                    <HierarchicalBreadcrumbPopover
                      selectedItemLabel={item.label}
                      items={isFirst ? items : item.children || []}
                      pathname={pathname}
                      hierarchy={hierarchy}
                    />
                  </div>
                )}
              </BreadcrumbItem>
              {!isLast && (
                <BreadcrumbSeparator className='text-muted-foreground/50'>
                  <Slash className='h-3.5 w-3.5' />
                </BreadcrumbSeparator>
              )}
            </React.Fragment>
          )
        })}
      </BreadcrumbList>
    </Breadcrumb>
  )
}
