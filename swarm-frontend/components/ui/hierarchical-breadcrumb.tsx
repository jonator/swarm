'use client'

import { Check, ChevronsUpDown, CirclePlus, Search, Slash } from 'lucide-react'
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

interface HierarchicalItem {
  label: string
  href?: string
  isActive?: boolean
  children?: HierarchicalItem[]
}

interface HierarchicalBreadcrumbProps {
  items: HierarchicalItem[]
  className?: string
}

function HierarchicalBreadcrumbPopover({
  items,
  levelIndex,
  onSelect,
}: {
  items: HierarchicalItem[]
  levelIndex: number
  onSelect?: (selectedItem: HierarchicalItem, levelIndex: number) => void
}) {
  const [searchTerms, setSearchTerms] = React.useState<string[]>(['', ''])

  // Get the two levels to display based on current position
  const currentLevel = items[levelIndex]
  const nextLevel = levelIndex < items.length - 1 ? items[levelIndex + 1] : null

  // Only include levels that have children
  const levelsToShow = [currentLevel, nextLevel].filter(
    (level) => level && level.children && level.children.length > 0,
  )

  // Filter items based on search terms
  const getFilteredChildren = (
    level: HierarchicalItem,
    searchIndex: number,
  ) => {
    if (!level.children) return []
    const searchTerm = searchTerms[searchIndex]?.toLowerCase() || ''
    return level.children.filter((child) =>
      child.label.toLowerCase().includes(searchTerm),
    )
  }

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button
          variant='ghost'
          size='sm'
          className={cn(
            'flex items-center justify-center px-1 py-1.5 transition-colors',
            'hover:bg-accent hover:text-accent-foreground',
            'text-muted-foreground hover:text-foreground',
            // "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
            'h-auto',
          )}
        >
          <ChevronsUpDown className='h-3.5 w-3.5' />
        </Button>
      </PopoverTrigger>
      <PopoverContent className='p-3 w-fit' align='start' sideOffset={8}>
        <div className='flex gap-3'>
          {levelsToShow.map((levelItem, columnIndex) => {
            if (!levelItem?.children || levelItem.children.length === 0)
              return null

            const filteredChildren = getFilteredChildren(levelItem, columnIndex)
            const actualLevelIndex = levelIndex + columnIndex

            return (
              <div
                key={`level-${actualLevelIndex}`}
                className='space-y-3 max-w-xs'
              >
                {/* Header */}
                <div className='space-y-2'>
                  <h4 className='text-xs font-medium text-muted-foreground uppercase tracking-wider truncate'>
                    {levelItem.label}
                  </h4>

                  {/* Search box */}
                  <div className='relative'>
                    <Search className='absolute left-2 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground' />
                    <Input
                      placeholder={`Search...`}
                      value={searchTerms[columnIndex] || ''}
                      onChange={(e) => {
                        const newSearchTerms = [...searchTerms]
                        newSearchTerms[columnIndex] = e.target.value
                        setSearchTerms(newSearchTerms)
                      }}
                      className='pl-8 h-8 text-sm'
                    />
                  </div>
                </div>

                {/* Items list and create button grouped together */}
                <div className='space-y-0'>
                  {/* Items list */}
                  <div className='space-y-0.5 max-h-64 overflow-y-auto'>
                    {filteredChildren.map((child, childIndex) => (
                      <Button
                        key={`${child.label}-${childIndex}`}
                        variant='ghost'
                        size='sm'
                        className={cn(
                          'w-full justify-between px-2 py-1.5 h-auto text-sm font-normal',
                          'hover:bg-accent/50 focus:bg-accent/50',
                          child.isActive && 'bg-accent text-accent-foreground',
                          'transition-colors',
                        )}
                        onClick={() => {
                          if (child.href) {
                            window.location.href = child.href
                          }
                          onSelect?.(child, actualLevelIndex)
                        }}
                      >
                        <span className='truncate'>{child.label}</span>
                        {child.isActive && (
                          <Check className='h-3.5 w-3.5 text-primary flex-shrink-0' />
                        )}
                      </Button>
                    ))}

                    {filteredChildren.length === 0 &&
                      searchTerms[columnIndex] && (
                        <div className='px-2 py-4 text-sm text-muted-foreground text-center'>
                          No results found
                        </div>
                      )}
                  </div>

                  {/* Create button */}
                  <Button
                    variant='ghost'
                    size='sm'
                    className={cn(
                      'w-full justify-start px-2 py-1.5 h-auto text-sm font-normal',
                      'text-muted-foreground hover:text-foreground',
                      'border-t border-border/50 rounded-none rounded-b-sm pt-2',
                    )}
                    onClick={() => {
                      // Handle create action
                      console.log(`Create new ${levelItem.label.toLowerCase()}`)
                    }}
                  >
                    <CirclePlus className='h-3.5 w-3.5 mr-2 flex-shrink-0' />
                    <span className='truncate'>Create</span>
                  </Button>
                </div>
              </div>
            )
          })}
        </div>
      </PopoverContent>
    </Popover>
  )
}

function HierarchicalBreadcrumbDropdown({
  item,
  allItems,
  levelIndex,
  selectedItems,
  onSelect,
}: {
  item: HierarchicalItem
  allItems: HierarchicalItem[]
  levelIndex: number
  selectedItems: HierarchicalItem[]
  onSelect?: (selectedItem: HierarchicalItem, levelIndex: number) => void
}) {
  // If no children, just show as a simple link
  if (!item.children || item.children.length === 0) {
    return <BreadcrumbLink href={item.href}>{item.label}</BreadcrumbLink>
  }

  // Get the current selection for this level
  const currentSelection =
    selectedItems[levelIndex] ||
    item.children.find((child) => child.isActive) ||
    item.children[0]

  return (
    <div className='flex items-center gap-1'>
      {/* Current selection navigation button */}
      <BreadcrumbLink href={currentSelection.href}>
        {currentSelection.label}
      </BreadcrumbLink>

      <HierarchicalBreadcrumbPopover
        items={allItems}
        levelIndex={levelIndex}
        onSelect={onSelect}
      />
    </div>
  )
}

export function HierarchicalBreadcrumb({
  items,
  className,
}: HierarchicalBreadcrumbProps) {
  const [selectedItems, setSelectedItems] = React.useState<HierarchicalItem[]>(
    [],
  )

  const handleSelect = React.useCallback(
    (item: HierarchicalItem, levelIndex: number) => {
      setSelectedItems((prev) => {
        const newSelected = [...prev]
        newSelected[levelIndex] = item
        // Clear any selections after this level
        return newSelected.slice(0, levelIndex + 1)
      })
    },
    [items],
  )

  return (
    <Breadcrumb className={className}>
      <BreadcrumbList className='flex items-center gap-1'>
        {items.map((item, index) => {
          const isLast = index === items.length - 1
          const selectedItem = selectedItems[index] || item

          return (
            <React.Fragment key={`${item.label}-${index}`}>
              <BreadcrumbItem>
                {isLast && !item.children ? (
                  <BreadcrumbPage
                    className={cn(
                      'flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-sm font-medium',
                      'text-foreground',
                    )}
                  >
                    {selectedItem.label}
                  </BreadcrumbPage>
                ) : (
                  <HierarchicalBreadcrumbDropdown
                    item={item}
                    allItems={items}
                    levelIndex={index}
                    selectedItems={selectedItems}
                    onSelect={(selected) => handleSelect(selected, index)}
                  />
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
