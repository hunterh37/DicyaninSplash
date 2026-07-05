#if os(visionOS)
import ShaderGraphCoder
import RealityKit

/// Animated cyber-green wireframe + energy-sweep emissive material. Apply to any mesh to
/// give it the DicyaninLabs "rendering in" look used behind the splash title.
public func makeWiremeshCyberGreenShader() async throws -> ShaderGraphMaterial {
    let time = SGValue.time
    let worldPos = SGValue.position(space: .world)
    let intensity = SGValue.floatParameter(name: "Intensity", defaultValue: 0.8)

    let gridScale = SGValue.float(16.0)
    let lineWidth = SGValue.float(0.015)

    let gx = abs(fract(worldPos.x * gridScale) - SGValue.float(0.5))
    let gy = abs(fract(worldPos.y * gridScale) - SGValue.float(0.5))
    let gz = abs(fract(worldPos.z * gridScale) - SGValue.float(0.5))

    let lineX = SGValue.float(1.0) - smoothStep(gx, low: SGValue.float(0.0), high: lineWidth)
    let lineY = SGValue.float(1.0) - smoothStep(gy, low: SGValue.float(0.0), high: lineWidth)
    let lineZ = SGValue.float(1.0) - smoothStep(gz, low: SGValue.float(0.0), high: lineWidth)
    let wireframe = max(max(lineX, lineY), lineZ)

    let pulseX = sin(worldPos.x * SGValue.float(6.0) + time * SGValue.float(2.5))
    let pulseY = sin(worldPos.y * SGValue.float(5.0) + time * SGValue.float(1.8))
    let pulseZ = sin(worldPos.z * SGValue.float(4.0) + time * SGValue.float(3.2))
    let energyPulse = pulseX * pulseY * pulseZ * SGValue.float(0.5) + SGValue.float(0.5)

    let sweep = fract(time * SGValue.float(0.3))
    let sweepLine = abs(worldPos.y * SGValue.float(0.5) - sweep * SGValue.float(2.0))
    let sweepGlow = SGValue.float(1.0) - smoothStep(sweepLine, low: SGValue.float(0.0), high: SGValue.float(0.15))

    let totalBrightness = wireframe * (SGValue.float(0.3) + energyPulse * SGValue.float(0.7))
                        + sweepGlow * SGValue.float(1.2) * wireframe

    let cyberGreen = SGValue.color3f(0.0, 1.0, 0.25)
    let emissive = cyberGreen * (totalBrightness * intensity * SGValue.float(3.0))

    let base = SGValue.color3f(0.002, 0.015, 0.005)

    return try await ShaderGraphMaterial(surface: pbrSurface(
        baseColor: base,
        emissiveColor: emissive,
        roughness: SGValue.float(0.3),
        metallic: SGValue.float(0.0),
        opacity: SGValue.float(1.0)
    ))
}

#endif
