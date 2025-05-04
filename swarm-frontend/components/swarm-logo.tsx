'use client'

export default function SwarmLogo({
  size = 40,
  className = '',
}: {
  size?: number
  className?: string
}) {
  return (
    <div
      className={`relative text-foreground ${className}`}
      style={{ width: size, height: size }}
    >
      <svg
        width={size}
        height={size}
        viewBox='0 0 32 32'
        xmlns='http://www.w3.org/2000/svg'
      >
        <polygon
          points='16,1.5999999999999996 28.470399999999998,8.8 28.470399999999998,23.2 16,30.4 3.5296000000000003,23.2 3.5296000000000003,8.8'
          fill='currentColor'
        />
      </svg>
    </div>
  )
}
