export default function SwarmLogo({
  size = 40,
  className = "",
}: {
  size?: number;
  className?: string;
}) {
  // Hexagon parameters
  const center = size / 2;
  const hexRadius = size * 0.45; // Slightly smaller than half to leave some margin

  // Calculate points for hexagon shape
  const hexPoints = [
    [center, center - hexRadius], // top
    [center + hexRadius * 0.866, center - hexRadius * 0.5], // top right
    [center + hexRadius * 0.866, center + hexRadius * 0.5], // bottom right
    [center, center + hexRadius], // bottom
    [center - hexRadius * 0.866, center + hexRadius * 0.5], // bottom left
    [center - hexRadius * 0.866, center - hexRadius * 0.5], // top left
  ];

  // Convert points array to SVG points string
  const hexPointsString = hexPoints.map((point) => point.join(",")).join(" ");

  return (
    <div
      className={`relative ${className}`}
      style={{ width: size, height: size }}
    >
      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* Simple white hexagon */}
        <polygon points={hexPointsString} fill="white" />
      </svg>
    </div>
  );
}
