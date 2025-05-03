import Image from "next/image";

export default function SwarmLogo({
  size = 40,
  className = "",
}: {
  size?: number;
  className?: string;
}) {
  return (
    <div
      className={`relative ${className}`}
      style={{ width: size, height: size }}
    >
      <Image src="/logo.svg" alt="Swarm Logo" width={32} height={32} />
    </div>
  );
}
