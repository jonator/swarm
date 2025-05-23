"use client";

import * as React from "react";
import { ChevronsUpDown, Slash, Check, Search, Plus } from "lucide-react";

import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils/shadcn";

interface HierarchicalItem {
  label: string;
  href?: string;
  isActive?: boolean;
  children?: HierarchicalItem[];
}

interface HierarchicalBreadcrumbProps {
  items: HierarchicalItem[];
  className?: string;
}

function HierarchicalBreadcrumbPopover({
  items,
  currentPath,
  levelIndex,
  onSelect,
}: {
  items: HierarchicalItem[];
  currentPath: number[];
  levelIndex: number;
  onSelect?: (selectedItem: HierarchicalItem, levelIndex: number) => void;
}) {
  const [searchTerms, setSearchTerms] = React.useState<string[]>(["", ""]);

  // Get the two levels to display based on current position
  const currentLevel = items[levelIndex];
  const nextLevel =
    levelIndex < items.length - 1 ? items[levelIndex + 1] : null;

  const levelsToShow = [currentLevel, nextLevel].filter(Boolean);

  // Filter items based on search terms
  const getFilteredChildren = (
    level: HierarchicalItem,
    searchIndex: number
  ) => {
    if (!level.children) return [];
    const searchTerm = searchTerms[searchIndex]?.toLowerCase() || "";
    return level.children.filter((child) =>
      child.label.toLowerCase().includes(searchTerm)
    );
  };

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          className={cn(
            "flex items-center justify-center rounded-r-md px-1.5 py-1.5 transition-colors",
            "hover:bg-accent hover:text-accent-foreground",
            "text-muted-foreground hover:text-foreground",
            "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
            "h-auto"
          )}
        >
          <ChevronsUpDown className="h-3.5 w-3.5" />
        </Button>
      </PopoverTrigger>
      <PopoverContent
        className="w-auto p-3 min-w-[500px]"
        align="start"
        sideOffset={8}
      >
        <div className="grid grid-cols-2 gap-4">
          {levelsToShow.map((levelItem, columnIndex) => {
            if (!levelItem?.children || levelItem.children.length === 0)
              return null;

            const filteredChildren = getFilteredChildren(
              levelItem,
              columnIndex
            );
            const actualLevelIndex = levelIndex + columnIndex;

            return (
              <div key={`level-${actualLevelIndex}`} className="space-y-3">
                {/* Header */}
                <div className="space-y-2">
                  <h4 className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                    {levelItem.label}
                  </h4>

                  {/* Search box */}
                  <div className="relative">
                    <Search className="absolute left-2 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
                    <Input
                      placeholder={`Search ${levelItem.label.toLowerCase()}...`}
                      value={searchTerms[columnIndex] || ""}
                      onChange={(e) => {
                        const newSearchTerms = [...searchTerms];
                        newSearchTerms[columnIndex] = e.target.value;
                        setSearchTerms(newSearchTerms);
                      }}
                      className="pl-8 h-8 text-sm"
                    />
                  </div>
                </div>

                {/* Items list */}
                <div className="space-y-0.5 max-h-64 overflow-y-auto">
                  {filteredChildren.map((child, childIndex) => (
                    <Button
                      key={`${child.label}-${childIndex}`}
                      variant="ghost"
                      size="sm"
                      className={cn(
                        "w-full justify-between px-2 py-1.5 h-auto text-sm font-normal",
                        "hover:bg-accent/50 focus:bg-accent/50",
                        child.isActive && "bg-accent text-accent-foreground",
                        "transition-colors"
                      )}
                      onClick={() => {
                        if (child.href) {
                          window.location.href = child.href;
                        }
                        onSelect?.(child, actualLevelIndex);
                      }}
                    >
                      <span className="truncate">{child.label}</span>
                      {child.isActive && (
                        <Check className="h-3.5 w-3.5 text-primary" />
                      )}
                    </Button>
                  ))}

                  {filteredChildren.length === 0 &&
                    searchTerms[columnIndex] && (
                      <div className="px-2 py-4 text-sm text-muted-foreground text-center">
                        No results found
                      </div>
                    )}
                </div>

                {/* Create button */}
                <Button
                  variant="ghost"
                  size="sm"
                  className={cn(
                    "w-full justify-start px-2 py-1.5 h-auto text-sm font-normal",
                    "text-muted-foreground hover:text-foreground",
                    "border-t border-border/50 rounded-none rounded-b-sm mt-2 pt-2"
                  )}
                  onClick={() => {
                    // Handle create action
                    console.log(`Create new ${levelItem.label.toLowerCase()}`);
                  }}
                >
                  <Plus className="h-3.5 w-3.5 mr-2" />
                  Create {levelItem.label.slice(0, -1)}{" "}
                  {/* Remove 's' from plural */}
                </Button>
              </div>
            );
          })}
        </div>
      </PopoverContent>
    </Popover>
  );
}

function HierarchicalBreadcrumbDropdown({
  item,
  allItems,
  currentPath,
  levelIndex,
  onSelect,
}: {
  item: HierarchicalItem;
  allItems: HierarchicalItem[];
  currentPath: number[];
  levelIndex: number;
  onSelect?: (selectedItem: HierarchicalItem, levelIndex: number) => void;
}) {
  if (!item.children || item.children.length === 0) {
    return (
      <BreadcrumbLink
        href={item.href}
        className={cn(
          "flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-sm font-medium transition-colors",
          "hover:bg-accent hover:text-accent-foreground",
          "text-muted-foreground hover:text-foreground"
        )}
      >
        {item.label}
      </BreadcrumbLink>
    );
  }

  return (
    <div className="flex items-center">
      <BreadcrumbLink
        href={item.href}
        className={cn(
          "flex items-center rounded-l-md px-2.5 py-1.5 text-sm font-medium transition-colors",
          "hover:bg-accent hover:text-accent-foreground",
          "text-muted-foreground hover:text-foreground"
        )}
      >
        {item.label}
      </BreadcrumbLink>

      <HierarchicalBreadcrumbPopover
        items={allItems}
        currentPath={currentPath}
        levelIndex={levelIndex}
        onSelect={onSelect}
      />
    </div>
  );
}

export function HierarchicalBreadcrumb({
  items,
  className,
}: HierarchicalBreadcrumbProps) {
  const [selectedItems, setSelectedItems] = React.useState<HierarchicalItem[]>(
    []
  );
  const [currentPath, setCurrentPath] = React.useState<number[]>([]);

  const handleSelect = React.useCallback(
    (item: HierarchicalItem, levelIndex: number) => {
      setSelectedItems((prev) => {
        const newSelected = [...prev];
        newSelected[levelIndex] = item;
        // Clear any selections after this level
        return newSelected.slice(0, levelIndex + 1);
      });

      setCurrentPath((prev) => {
        const newPath = [...prev];
        newPath[levelIndex] =
          items[levelIndex]?.children?.findIndex(
            (child) => child.label === item.label
          ) ?? 0;
        return newPath.slice(0, levelIndex + 1);
      });
    },
    [items]
  );

  return (
    <Breadcrumb className={className}>
      <BreadcrumbList className="flex items-center gap-1">
        {items.map((item, index) => {
          const isLast = index === items.length - 1;
          const selectedItem = selectedItems[index] || item;

          return (
            <React.Fragment key={`${item.label}-${index}`}>
              <BreadcrumbItem>
                {isLast && !item.children ? (
                  <BreadcrumbPage
                    className={cn(
                      "flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-sm font-medium",
                      "text-foreground"
                    )}
                  >
                    {selectedItem.label}
                  </BreadcrumbPage>
                ) : (
                  <HierarchicalBreadcrumbDropdown
                    item={item}
                    allItems={items}
                    currentPath={currentPath}
                    levelIndex={index}
                    onSelect={(selected) => handleSelect(selected, index)}
                  />
                )}
              </BreadcrumbItem>
              {!isLast && (
                <BreadcrumbSeparator className="text-muted-foreground/50">
                  <Slash className="h-3.5 w-3.5" />
                </BreadcrumbSeparator>
              )}
            </React.Fragment>
          );
        })}
      </BreadcrumbList>
    </Breadcrumb>
  );
}

// Example usage component for demonstration
export function HierarchicalBreadcrumbExample() {
  const breadcrumbItems: HierarchicalItem[] = [
    {
      label: "Teams",
      href: "/teams",
      children: [
        { label: "Jon Ator's projects", href: "/personal", isActive: true },
        { label: "Work Team", href: "/work" },
        { label: "Open Source", href: "/oss" },
      ],
    },
    {
      label: "Projects",
      href: "/projects",
      children: [
        { label: "polaris-web", href: "/polaris-web" },
        { label: "homepage", href: "/homepage", isActive: true },
        { label: "blog", href: "/blog" },
      ],
    },
    {
      label: "Environment",
      href: "/environment",
      children: [
        { label: "Production", href: "/production", isActive: true },
        { label: "Preview", href: "/preview" },
        { label: "Development", href: "/development" },
      ],
    },
  ];

  return (
    <div className="p-6 bg-background">
      <HierarchicalBreadcrumb items={breadcrumbItems} className="mb-4" />
    </div>
  );
}
