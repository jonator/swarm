'use client'

import {
  Environment,
  Float,
  OrbitControls,
  Sphere,
  Trail,
} from '@react-three/drei'
import { Canvas, useFrame } from '@react-three/fiber'
import { useTheme } from 'next-themes'
import { useEffect, useMemo, useRef, useState } from 'react'
import * as THREE from 'three'
import { useMobile } from '../hooks/use-mobile'

// Define ParticlesBackground component (replace with your actual implementation)
function ParticlesBackground() {
  return null // Placeholder: Replace with your particle background implementation
}

interface GitHubLogoProps {
  position: [number, number, number]
}

function GitHubLogo({ position }: GitHubLogoProps) {
  const ref = useRef<THREE.Mesh>(null)
  const [hovered, setHovered] = useState(false)
  const [active, setActive] = useState(false)

  useFrame(({ clock }) => {
    if (!ref.current) return

    const t = clock.getElapsedTime()

    // Gentle floating rotation
    ref.current.rotation.y = t * 0.2
    ref.current.rotation.x = Math.sin(t * 0.1) * 0.1

    // Pulse effect when active
    if (active) {
      const scale = 1 + Math.sin(t * 4) * 0.05
      ref.current.scale.set(scale, scale, scale)
    } else {
      ref.current.scale.setScalar(hovered ? 1.2 : 1)
    }
  })

  return (
    <Float
      speed={1.5}
      rotationIntensity={0.2}
      floatIntensity={0.3}
      position={position}
    >
      {/* biome-ignore lint/a11y/noStaticElementInteractions: Three.js <group> is used for 3D interactivity and cannot use role or tabIndex */}
      <group
        ref={ref}
        onPointerOver={() => setHovered(true)}
        onPointerOut={() => setHovered(false)}
        onClick={() => setActive(!active)}
      >
        {/* Improved GitHub logo */}
        <mesh>
          <octahedronGeometry args={[0.8, 0]} />
          <meshStandardMaterial
            color='hsl(var(--foreground))'
            emissive='hsl(var(--foreground))'
            emissiveIntensity={active ? 2 : 0.8}
            metalness={0.8}
            roughness={0.2}
          />
        </mesh>

        {/* Glow effect */}
        <mesh>
          <sphereGeometry args={[1, 16, 16]} />
          <meshBasicMaterial
            color='hsl(var(--primary))'
            transparent={true}
            opacity={0.15}
          />
        </mesh>
      </group>
    </Float>
  )
}

interface LightningBoltProps {
  startRef: React.RefObject<THREE.Vector3>
  end: [number, number, number]
  active: boolean
}

function LightningBolt({ startRef, end, active }: LightningBoltProps) {
  const ref = useRef<THREE.Mesh>(null)
  const pointsRef = useRef<THREE.Vector3[]>([])
  const intervalRef = useRef<NodeJS.Timeout | null>(null)

  useEffect(() => {
    if (!active) return

    const generateLightningPoints = () => {
      if (!startRef.current) return []

      const startVec = startRef.current.clone()
      const endVec = new THREE.Vector3(...end)
      const direction = endVec.clone().sub(startVec)
      const length = direction.length()
      const segments = Math.floor(length * 2) + 2

      const points = [startVec.clone()]

      for (let i = 1; i < segments; i++) {
        const t = i / segments
        const pos = startVec.clone().lerp(endVec, t)

        if (i !== segments - 1) {
          const jitter = 0.3 - t * 0.2
          pos.x += (Math.random() - 0.5) * jitter
          pos.y += (Math.random() - 0.5) * jitter
          pos.z += (Math.random() - 0.5) * jitter
        }

        points.push(pos)
      }

      points.push(endVec.clone())
      return points
    }

    pointsRef.current = generateLightningPoints()

    intervalRef.current = setInterval(
      () => {
        pointsRef.current = generateLightningPoints()
      },
      100 + Math.random() * 200,
    )

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current)
    }
  }, [active, end, startRef])

  useFrame(() => {
    if (!ref.current || !active || pointsRef.current.length < 2) return

    const curve = new THREE.CatmullRomCurve3(pointsRef.current)
    ref.current.geometry.dispose()
    ref.current.geometry = new THREE.TubeGeometry(curve, 64, 0.02, 8, false)
  })

  if (!active) return null

  return (
    <mesh ref={ref}>
      <tubeGeometry
        args={[
          new THREE.CatmullRomCurve3([
            new THREE.Vector3(0, 0, 0),
            new THREE.Vector3(0, 0, 0.001),
          ]),
          64,
          0.02,
          8,
          false,
        ]}
      />
      <meshStandardMaterial
        color='hsl(var(--primary))'
        emissive='hsl(var(--primary))'
        emissiveIntensity={2}
      />
    </mesh>
  )
}

interface AISpriteProps {
  position: [number, number, number]
  target: [number, number, number]
  isActive: boolean
}

function AISprite({ position, target, isActive }: AISpriteProps) {
  const ref = useRef<THREE.Group>(null)
  const [active, setActive] = useState(isActive)
  const positionRef = useRef(new THREE.Vector3(...position))
  const targetPosition = useMemo(() => new THREE.Vector3(...target), [target])

  // Create a unique orbit path for each sprite
  const orbitRadius = useMemo(() => 2 + Math.random() * 3, [])
  const orbitSpeed = useMemo(() => 0.2 + Math.random() * 0.3, [])
  const orbitOffset = useMemo(() => Math.random() * Math.PI * 2, [])
  const verticalOffset = useMemo(() => (Math.random() - 0.5) * 2, [])

  useFrame(({ clock }) => {
    if (!ref.current) return

    const t = clock.getElapsedTime()

    // Orbital movement
    const x = Math.cos(t * orbitSpeed + orbitOffset) * orbitRadius
    const z = Math.sin(t * orbitSpeed + orbitOffset) * orbitRadius
    const y = Math.sin(t * 0.5) * 0.5 + verticalOffset

    ref.current.position.set(x, y, z)
    positionRef.current.set(x, y, z)

    // Always look at the target
    ref.current.lookAt(targetPosition)
  })

  return (
    <>
      <group ref={ref} position={position}>
        <Trail
          width={0.05}
          length={4}
          color='hsl(var(--primary))'
          attenuation={(t) => t * t}
        >
          <Sphere args={[0.15, 16, 16]} onClick={() => setActive(!active)}>
            <meshStandardMaterial
              color='hsl(var(--primary))'
              emissive='hsl(var(--primary))'
              emissiveIntensity={2}
              transparent
              opacity={0.7}
            />
          </Sphere>
        </Trail>
      </group>

      {/* Lightning bolt to target */}
      <LightningBolt startRef={positionRef} end={target} active={active} />
    </>
  )
}

// Update the main visualization component
export default function SwarmVisualization() {
  const isMobile = useMobile()
  const { resolvedTheme } = useTheme()

  // Map theme to background color
  const backgroundColor = resolvedTheme === 'dark' ? '#0A0A0A' : '#fff'

  // Create AI sprites and GitHub logos
  const aiCount = isMobile ? 8 : 15
  const githubCount = isMobile ? 2 : 3

  // Create GitHub logos in the center
  const githubLogos = useMemo(() => {
    return Array.from({ length: githubCount }).map((_, i) => {
      const angle = (i / githubCount) * Math.PI * 2
      const radius = 1.2
      const x = Math.cos(angle) * radius
      const z = Math.sin(angle) * radius
      const y = (Math.random() - 0.5) * 1.2

      return {
        position: [x, y, z] as [number, number, number],
      }
    })
  }, [githubCount])

  // Create AI sprites that orbit around
  const aiSprites = useMemo(
    () =>
      Array.from({ length: aiCount }).map((_, i) => {
        const angle = (i / aiCount) * Math.PI * 2
        const radius = 4 + Math.random() * 2
        const x = Math.cos(angle) * radius
        const z = Math.sin(angle) * radius
        const y = (Math.random() - 0.5) * 4

        const targetLogo = githubLogos[i % githubLogos.length]

        return {
          position: [x, y, z] as [number, number, number],
          target: targetLogo.position as [number, number, number],
          isActive: Math.random() > 0.5,
        }
      }),
    [aiCount, githubLogos],
  )

  return (
    <Canvas camera={{ position: [0, 0, 10], fov: 50 }}>
      <color attach='background' args={[backgroundColor]} />
      <ambientLight intensity={0.2} />
      <spotLight
        position={[10, 10, 10]}
        angle={0.15}
        penumbra={1}
        intensity={1}
      />

      <ParticlesBackground />

      {/* Render GitHub logos first (in the center) */}
      {githubLogos.map((logo, i) => (
        <GitHubLogo key={`github-${i}`} position={logo.position} />
      ))}

      {/* Then render AI sprites with lightning connections */}
      {aiSprites.map((sprite, i) => (
        <AISprite
          key={`ai-${i}`}
          position={sprite.position}
          target={sprite.target}
          isActive={sprite.isActive}
        />
      ))}

      <Environment preset='dawn' />
      <OrbitControls
        enableZoom={false}
        enablePan={false}
        rotateSpeed={0.5}
        autoRotate
        autoRotateSpeed={0.5}
      />
    </Canvas>
  )
}
