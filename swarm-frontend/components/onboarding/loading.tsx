'use client'

import { Card, CardContent, CardHeader } from '../ui/card'
import { Skeleton } from '../ui/skeleton'

export const SkeletonCard = ({
  bodyContent = false,
}: { bodyContent?: boolean }) => (
  <Card className='w-96'>
    <CardHeader>
      <Skeleton className='w-full h-10' />
    </CardHeader>
    <CardContent>
      {bodyContent && (
        <div className='space-y-2 py-2'>
          <Skeleton className='h-4 w-full' />
          <Skeleton className='h-4 w-3/4' />
        </div>
      )}
      <Skeleton className='w-full h-9' />
    </CardContent>
  </Card>
)
