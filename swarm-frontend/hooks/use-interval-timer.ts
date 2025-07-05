import { useEffect, useState } from 'react'

/**
 * useIntervalTimer
 * @param initialValue - The initial Date value for the timer (e.g., new Date())
 * @param enabled - Whether the timer should be running
 * @param intervalMs - Interval in milliseconds (default: 1000)
 * @returns current Date value
 */
export function useIntervalTimer(
  initialValue: Date,
  enabled: boolean,
  intervalMs = 1000,
): Date {
  const [currentValue, setCurrentValue] = useState<Date>(initialValue)

  useEffect(() => {
    if (!enabled) return
    const interval = setInterval(() => {
      setCurrentValue(new Date())
    }, intervalMs)
    return () => {
      clearInterval(interval)
    }
  }, [enabled, intervalMs])

  return currentValue
}
