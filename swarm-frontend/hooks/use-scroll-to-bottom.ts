import { useCallback, useLayoutEffect, useRef, useState } from 'react'

type ScrollFlag = ScrollBehavior | false

export function useScrollToBottom() {
  const containerRef = useRef<HTMLDivElement>(null)
  const endRef = useRef<HTMLDivElement>(null)

  // Initialize as true so first messages auto-scroll
  const [isAtBottom, setIsAtBottom] = useState(true)
  const [scrollBehavior, setScrollBehavior] = useState<ScrollFlag>(false)

  // Use useLayoutEffect for better timing with DOM updates
  useLayoutEffect(() => {
    if (scrollBehavior) {
      endRef.current?.scrollIntoView({ behavior: scrollBehavior })
      setScrollBehavior(false)
    }
  }, [scrollBehavior])

  const scrollToBottom = useCallback(
    (scrollBehavior: ScrollBehavior = 'smooth') => {
      setScrollBehavior(scrollBehavior)
    },
    [],
  )

  const onViewportEnter = useCallback(() => {
    setIsAtBottom(true)
  }, [])

  const onViewportLeave = useCallback(() => {
    setIsAtBottom(false)
  }, [])

  return {
    containerRef,
    endRef,
    isAtBottom,
    scrollToBottom,
    onViewportEnter,
    onViewportLeave,
  }
}
