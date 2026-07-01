import SwiftUI
import RealityKit

/// A self-contained holographic 3D title scene: layered chromatic-aberration extruded text,
/// scrolling scanline bands, orbiting particle orbs, and flicker lighting. Generalised from
/// the original "SPATIAL ZOMBIES" splash centrepiece. Renders entirely from parameters, so it
/// ships no bundled assets.
public struct HoloTitleView: View {
    public var text: String
    public var theme: SplashTheme

    @State private var root: Entity? = nil
    @State private var animTimer: Timer? = nil
    @State private var t: Float = 0

    public init(_ text: String, theme: SplashTheme = .cyberGreen) {
        self.text = text
        self.theme = theme
    }

    private var accent: UIColor { theme.accentUIColor }

    public var body: some View {
        RealityView { content in
            let r = await buildScene()
            content.add(r)
            root = r
            startTimer()
        }
        .onDisappear { animTimer?.invalidate() }
    }

    private func startTimer() {
        animTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in
                t += 1.0 / 60.0
                guard let r = root else { return }
                animateScene(root: r, t: t)
            }
        }
    }

    @MainActor
    private func buildScene() async -> Entity {
        let r = Entity()
        r.name = "HoloTitleRoot"

        let titleE = buildHoloText(
            text, fontSize: 0.066, extrusionDepth: 0.008, baseName: "Title",
            primary: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.92)
        )
        titleE.name = "TitleWord"
        titleE.position = [0, 0.045, 0]
        r.addChild(titleE)

        for i in 0..<14 {
            var scanMat = UnlitMaterial(color: accent.withAlphaComponent(0.07))
            scanMat.blending = .transparent(opacity: .init(floatLiteral: 0.07))
            let scan = ModelEntity(
                mesh: .generateBox(width: 0.58, height: 0.0012, depth: 0.02),
                materials: [scanMat]
            )
            scan.name = "Scan_\(i)"
            scan.position = [0, Float(i) * 0.038 - 0.26, 0.008]
            r.addChild(scan)
        }

        for i in 0..<20 {
            let angle = Float(i) / 20.0 * .pi * 2
            let radius: Float = [0.19, 0.25, 0.31][i % 3]
            let orbWrap = Entity()
            orbWrap.name = "Orb_\(i)"
            let size: Float = 0.0022 + Float(i % 4) * 0.0009
            var mat = UnlitMaterial(color: accent.withAlphaComponent(0.9))
            mat.blending = .transparent(opacity: .init(floatLiteral: 0.9))
            orbWrap.addChild(ModelEntity(mesh: .generateSphere(radius: size), materials: [mat]))
            orbWrap.position = [cos(angle) * radius, sin(Float(i) * 1.2) * 0.07, sin(angle) * radius * 0.35]
            r.addChild(orbWrap)
        }

        var fill = PointLightComponent()
        fill.color = accent
        fill.intensity = 1700
        fill.attenuationRadius = 2.0
        let fillE = Entity()
        fillE.name = "FillLight"
        fillE.components.set(fill)
        fillE.position = [0, 0.1, 0.25]
        r.addChild(fillE)

        var rim = PointLightComponent()
        rim.color = UIColor(red: 0.15, green: 0.75, blue: 1.0, alpha: 1)
        rim.intensity = 700
        rim.attenuationRadius = 1.5
        let rimE = Entity()
        rimE.name = "RimLight"
        rimE.components.set(rim)
        rimE.position = [-0.20, 0.0, -0.12]
        r.addChild(rimE)

        return r
    }

    @MainActor
    private func buildHoloText(_ text: String, fontSize: CGFloat, extrusionDepth: Float, baseName: String, primary: UIColor) -> Entity {
        let container = Entity()

        guard let mesh = try? MeshResource.generateText(
            text,
            extrusionDepth: extrusionDepth,
            font: theme.uiFont(fontSize),
            containerFrame: .zero,
            alignment: .natural,
            lineBreakMode: .byWordWrapping
        ) else { return container }

        let cx = -mesh.bounds.center.x
        let cy = -mesh.bounds.center.y

        var mat1 = UnlitMaterial(color: primary)
        mat1.blending = .transparent(opacity: .init(floatLiteral: Float(primary.cgColor.alpha)))
        let face = ModelEntity(mesh: mesh, materials: [mat1])
        face.name = "\(baseName)_face"
        face.position = [cx, cy, 0]
        container.addChild(face)

        var mat2 = UnlitMaterial(color: primary.withAlphaComponent(0.20))
        mat2.blending = .transparent(opacity: .init(floatLiteral: 0.20))
        let shell = ModelEntity(mesh: mesh, materials: [mat2])
        shell.name = "\(baseName)_shell"
        shell.scale = SIMD3<Float>(repeating: 1.025)
        shell.position = [cx, cy, 0]
        container.addChild(shell)

        var mat3 = UnlitMaterial(color: accent.withAlphaComponent(0.07))
        mat3.blending = .transparent(opacity: .init(floatLiteral: 0.07))
        let glow = ModelEntity(mesh: mesh, materials: [mat3])
        glow.name = "\(baseName)_glow"
        glow.scale = SIMD3<Float>(repeating: 1.10)
        glow.position = [cx, cy, -0.004]
        container.addChild(glow)

        var matR = UnlitMaterial(color: UIColor(red: 1.0, green: 0.05, blue: 0.22, alpha: 0.26))
        matR.blending = .transparent(opacity: .init(floatLiteral: 0.26))
        let chromaR = ModelEntity(mesh: mesh, materials: [matR])
        chromaR.name = "\(baseName)_chromaR"
        chromaR.position = [cx + 0.020, cy + 0.002, 0.0015]
        container.addChild(chromaR)

        var matB = UnlitMaterial(color: UIColor(red: 0.10, green: 0.45, blue: 1.0, alpha: 0.22))
        matB.blending = .transparent(opacity: .init(floatLiteral: 0.22))
        let chromaB = ModelEntity(mesh: mesh, materials: [matB])
        chromaB.name = "\(baseName)_chromaB"
        chromaB.position = [cx - 0.020, cy - 0.002, 0.0015]
        container.addChild(chromaB)

        var lc = PointLightComponent()
        lc.color = accent
        lc.intensity = 950
        lc.attenuationRadius = 1.0
        let lightE = Entity()
        lightE.name = "\(baseName)_light"
        lightE.components.set(lc)
        lightE.position = [0, 0, 0.12]
        container.addChild(lightE)

        return container
    }

    private func animateScene(root: Entity, t: Float) {
        let slow   = (sin(t * 3.7) + 1) * 0.5
        let medium = (sin(t * 11.3 + 1.2) + 1) * 0.5
        let fast   = (sin(t * 37.1 + 2.9) + 1) * 0.5
        let blink: Float = (sin(t * 5.1) > 0.97 || sin(t * 2.3 + 0.5) > 0.98) ? 0.0 : 1.0
        let globalFlicker = (slow * 0.3 + medium * 0.2 + fast * 0.1 + 0.4) * blink

        let glitchCycle = t.truncatingRemainder(dividingBy: 4.5)
        let isGlitching = glitchCycle < 0.22
        let glitchPhase: Float = isGlitching ? glitchCycle / 0.22 : 0
        let glitchDropout: Float = isGlitching && sin(t * 320.0) > 0.0 ? 0.0 : 1.0
        let glitchChroma: Float = isGlitching ? (1.0 - glitchPhase) * 1.6 : 0.0

        if let titleE = root.findEntity(named: "TitleWord") {
            let fadeIn: Float = min(1.0, t * 2.5)
            let pulse = (0.82 + sin(t * 1.75) * 0.07 + sin(t * 3.9) * 0.03) * fadeIn
            let textBlink: Float = (sin(t * 4.3) > 0.97 || sin(t * 2.0 + 0.5) > 0.98) ? 0.42 : 1.0
            let baseOpacity = pulse * textBlink
            let glitchFaceS: Float = isGlitching ? glitchDropout * (1.0 + (1.0 - glitchPhase) * 0.5) : 1.0
            let opacity = baseOpacity * glitchFaceS

            if let face = titleE.findEntity(named: "Title_face") {
                face.components.set(OpacityComponent(opacity: min(1, opacity * 0.95)))
            }
            if let shell = titleE.findEntity(named: "Title_shell") {
                shell.components.set(OpacityComponent(opacity: opacity * 0.38 + glitchChroma * 0.15))
            }
            if let glow = titleE.findEntity(named: "Title_glow") {
                glow.components.set(OpacityComponent(opacity: opacity * 0.18 + glitchChroma * 0.55))
            }
            let chromaBoostS = fast > 0.70 ? fast : 0.0
            let chromaFloorS: Float = 0.35 * fadeIn
            if let chromaR = titleE.findEntity(named: "Title_chromaR") {
                chromaR.components.set(OpacityComponent(opacity: chromaFloorS + chromaBoostS * 0.30 * fadeIn + glitchChroma * 0.85))
            }
            if let chromaB = titleE.findEntity(named: "Title_chromaB") {
                chromaB.components.set(OpacityComponent(opacity: chromaFloorS * 0.85 + chromaBoostS * 0.22 * fadeIn + glitchChroma * 0.65))
            }
            if let lightE = titleE.findEntity(named: "Title_light") {
                var lc = lightE.components[PointLightComponent.self] ?? PointLightComponent()
                lc.intensity = (750 + sin(t * 1.75) * 180) * opacity + glitchChroma * 4800
                lightE.components.set(lc)
            }
        }

        for i in 0..<14 {
            if let scan = root.findEntity(named: "Scan_\(i)") {
                let speed: Float = 0.044 + Float(i % 4) * 0.017
                let scrollY = (t * speed + Float(i) * 0.038).truncatingRemainder(dividingBy: 0.53) - 0.265
                scan.position.y = scrollY
                let phase = Float(i) * 1.5 + t * speed * 5
                let opacity: Float = max(0, sin(phase) * 0.4 + 0.4) * (0.11 + Float(i % 3) * 0.05) * globalFlicker
                scan.components.set(OpacityComponent(opacity: opacity))
            }
        }

        for i in 0..<20 {
            if let orb = root.findEntity(named: "Orb_\(i)") {
                let baseAngle = Float(i) / 20.0 * .pi * 2
                let speed: Float = 0.13 + Float(i % 5) * 0.04
                let angle = baseAngle + t * speed
                let radius: Float = [0.19, 0.25, 0.31][i % 3]
                let vert: Float = 0.27 + Float(i % 5) * 0.09
                orb.position = [
                    cos(angle) * radius,
                    sin(t * vert + Float(i) * 0.7) * 0.07,
                    sin(angle) * radius * 0.35
                ]
                orb.components.set(OpacityComponent(opacity: globalFlicker * 0.72 + 0.28))
            }
        }

        if let fillE = root.findEntity(named: "FillLight") {
            var lc = fillE.components[PointLightComponent.self] ?? PointLightComponent()
            lc.intensity = 1400 + sin(t * 1.2) * 400 + globalFlicker * 550
            fillE.components.set(lc)
        }

        if let rimE = root.findEntity(named: "RimLight") {
            let angle = t * 0.32
            rimE.position = [cos(angle) * 0.22 - 0.18, sin(t * 0.52) * 0.05, sin(angle) * 0.12 - 0.10]
        }
    }
}
