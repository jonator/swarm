import { useRef, useEffect, useCallback, useState } from 'react'

type ScrollFlag = ScrollBehavior | false

export function useScrollToBottom() {
  const containerRef = useRef<HTMLDivElement>(null)
  const endRef = useRef<HTMLDivElement>(null)

  const [isAtBottom, setIsAtBottom] = useState(false)
  const [scrollBehavior, setScrollBehavior] = useState<ScrollFlag>(false)

  useEffect(() => {
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

  function onViewportEnter() {
    setIsAtBottom(true)
  }

  function onViewportLeave() {
    setIsAtBottom(false)
  }

  return {
    containerRef,
    endRef,
    isAtBottom,
    scrollToBottom,
    onViewportEnter,
    onViewportLeave,
  }
}
