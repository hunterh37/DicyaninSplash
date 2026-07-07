#if os(iOS)
import SwiftUI
import CoreMotion

/// Custom iOS launch splash: the app logo floats at the center of a wireframe
/// cyber-green cube interior. Device tilt (CoreMotion) plus a slow idle drift
/// shift the vanishing point so it feels like peering inside a 3D cube, with
/// glossy corner highlights and translucent glossy sidewalls.
///
/// Drop-in and asset-agnostic: pass the logo image name (resolved from the host
/// app's asset catalog), an accent color, and a hold duration.
public struct CubeLaunchSplashView: View {

    private let logoImageName: String
    private let accent: Color
    private let holdDuration: TimeInterval
    private let onFinished: () -> Void

    @StateObject private var motion = SplashMotion()
    @State private var appear = false
    @State private var logoPulse = false
    @State private var drift: CGFloat = 0
    @State private var finished = false

    public init(
        logoImageName: String,
        accent: Color = Color(red: 0.15, green: 1.0, blue: 0.45),
        holdDuration: TimeInterval = 2.6,
        onFinished: @escaping () -> Void = {}
    ) {
        self.logoImageName = logoImageName
        self.accent = accent
        self.holdDuration = holdDuration
        self.onFinished = onFinished
    }

    public var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let idle = CGPoint(
                x: sin(drift * .pi * 2) * 14,
                y: cos(drift * .pi * 2) * 10
            )
            let tilt = CGPoint(
                x: motion.offset.x * 60 + idle.x,
                y: motion.offset.y * 60 + idle.y
            )

            ZStack {
                Color.black.ignoresSafeArea()

                CubeInteriorView(parallax: tilt, accent: accent)
                    .opacity(appear ? 1 : 0)

                logo(tilt: tilt)
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { skip() }
        .onAppear { run() }
        .onDisappear { motion.stop() }
    }

    private func logo(tilt: CGPoint) -> some View {
        ZStack {
            // Ambient glow behind the logo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.35), .clear],
                        center: .center, startRadius: 4, endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .offset(x: tilt.x * -0.35, y: tilt.y * -0.35)

            Image(logoImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 300)
                .blendMode(.screen)
                .shadow(color: accent.opacity(logoPulse ? 0.8 : 0.35), radius: logoPulse ? 44 : 20)
                .rotation3DEffect(.degrees(Double(tilt.x) * 0.12), axis: (x: 0, y: 1, z: 0))
                .rotation3DEffect(.degrees(Double(tilt.y) * -0.12), axis: (x: 1, y: 0, z: 0))
                .offset(x: tilt.x * -0.55, y: tilt.y * -0.55)
                .scaleEffect(appear ? (logoPulse ? 1.03 : 1.0) : 0.7)
                .opacity(appear ? 1 : 0)
        }
    }

    private func run() {
        motion.start()
        withAnimation(.spring(response: 0.9, dampingFraction: 0.75)) { appear = true }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { logoPulse = true }
        withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) { drift = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) { skip() }
    }

    private func skip() {
        guard !finished else { return }
        finished = true
        withAnimation(.easeIn(duration: 0.5)) { appear = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onFinished() }
    }
}

/// Draws the interior of a cube (back wall plus four receding sidewalls) as a
/// cyber-green wireframe with glossy gradient walls and bright corner sheen.
/// The vanishing point shifts with `parallax` for the 3D peering effect.
private struct CubeInteriorView: View {

    let parallax: CGPoint
    let accent: Color

    private let backScale: CGFloat = 0.4
    private let gridDivisions = 4
    private let depthRings = 5

    var body: some View {
        Canvas { ctx, size in
            let outer = CGRect(origin: .zero, size: size).insetBy(dx: -2, dy: -2)
            let center = CGPoint(
                x: size.width / 2 + parallax.x,
                y: size.height / 2 + parallax.y
            )
            let back = backRect(center: center, size: size)

            drawWalls(ctx: &ctx, outer: outer, back: back)
            drawDepthRings(ctx: &ctx, outer: outer, back: back)
            drawWallGrid(ctx: &ctx, outer: outer, back: back)
            drawBackWall(ctx: &ctx, back: back)
            drawCornerEdges(ctx: &ctx, outer: outer, back: back)
            drawGlossyCorners(ctx: &ctx, back: back)
        }
        .allowsHitTesting(false)
    }

    private func backRect(center: CGPoint, size: CGSize) -> CGRect {
        let w = size.width * backScale
        let h = size.height * backScale
        return CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
    }

    private func corners(_ r: CGRect) -> [CGPoint] {
        [
            CGPoint(x: r.minX, y: r.minY),
            CGPoint(x: r.maxX, y: r.minY),
            CGPoint(x: r.maxX, y: r.maxY),
            CGPoint(x: r.minX, y: r.maxY)
        ]
    }

    private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    /// Translucent glossy sidewalls: each wall is a trapezoid from an outer
    /// edge to the matching back-wall edge, filled with a green sheen gradient.
    private func drawWalls(ctx: inout GraphicsContext, outer: CGRect, back: CGRect) {
        let o = corners(outer)
        let b = corners(back)
        for i in 0..<4 {
            let j = (i + 1) % 4
            var wall = Path()
            wall.move(to: o[i])
            wall.addLine(to: o[j])
            wall.addLine(to: b[j])
            wall.addLine(to: b[i])
            wall.closeSubpath()

            let mid = lerp(lerp(o[i], o[j], 0.5), lerp(b[i], b[j], 0.5), 0.5)
            ctx.fill(
                wall,
                with: .linearGradient(
                    Gradient(colors: [
                        accent.opacity(0.02),
                        accent.opacity(0.10),
                        Color.white.opacity(0.06)
                    ]),
                    startPoint: lerp(o[i], o[j], 0.5),
                    endPoint: mid
                )
            )
        }
    }

    /// Concentric depth rectangles between the screen edge and the back wall,
    /// fading and tightening with depth, selling the tunnel-into-a-cube look.
    private func drawDepthRings(ctx: inout GraphicsContext, outer: CGRect, back: CGRect) {
        let o = corners(outer)
        let b = corners(back)
        for ring in 1..<depthRings {
            let t = CGFloat(ring) / CGFloat(depthRings)
            var path = Path()
            path.move(to: lerp(o[0], b[0], t))
            for i in 1..<4 { path.addLine(to: lerp(o[i], b[i], t)) }
            path.closeSubpath()
            ctx.stroke(path, with: .color(accent.opacity(0.10 + 0.14 * Double(t))), lineWidth: 1)
        }
    }

    /// Wireframe grid lines running along each wall toward the back.
    private func drawWallGrid(ctx: inout GraphicsContext, outer: CGRect, back: CGRect) {
        let o = corners(outer)
        let b = corners(back)
        for i in 0..<4 {
            let j = (i + 1) % 4
            for g in 1..<gridDivisions {
                let t = CGFloat(g) / CGFloat(gridDivisions)
                var line = Path()
                line.move(to: lerp(o[i], o[j], t))
                line.addLine(to: lerp(b[i], b[j], t))
                ctx.stroke(line, with: .color(accent.opacity(0.18)), lineWidth: 1)
            }
        }
    }

    private func drawBackWall(ctx: inout GraphicsContext, back: CGRect) {
        // Faint glossy fill on the back wall
        ctx.fill(
            Path(back),
            with: .radialGradient(
                Gradient(colors: [accent.opacity(0.10), Color.black.opacity(0.0)]),
                center: CGPoint(x: back.midX, y: back.midY),
                startRadius: 0,
                endRadius: max(back.width, back.height) * 0.8
            )
        )
        // Back wall grid
        for g in 1..<gridDivisions {
            let t = CGFloat(g) / CGFloat(gridDivisions)
            var v = Path()
            v.move(to: CGPoint(x: back.minX + back.width * t, y: back.minY))
            v.addLine(to: CGPoint(x: back.minX + back.width * t, y: back.maxY))
            ctx.stroke(v, with: .color(accent.opacity(0.22)), lineWidth: 1)
            var h = Path()
            h.move(to: CGPoint(x: back.minX, y: back.minY + back.height * t))
            h.addLine(to: CGPoint(x: back.maxX, y: back.minY + back.height * t))
            ctx.stroke(h, with: .color(accent.opacity(0.22)), lineWidth: 1)
        }
        ctx.stroke(Path(back), with: .color(accent.opacity(0.9)), lineWidth: 2)
    }

    /// The four corner edges receding from screen corners to back-wall
    /// corners, stroked bright with a white glossy core.
    private func drawCornerEdges(ctx: inout GraphicsContext, outer: CGRect, back: CGRect) {
        let o = corners(outer)
        let b = corners(back)
        for i in 0..<4 {
            var edge = Path()
            edge.move(to: o[i])
            edge.addLine(to: b[i])
            var glow = ctx
            glow.addFilter(.blur(radius: 3))
            glow.stroke(edge, with: .color(accent.opacity(0.8)), lineWidth: 4)
            ctx.stroke(
                edge,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.9), accent]),
                    startPoint: o[i],
                    endPoint: b[i]
                ),
                lineWidth: 1.5
            )
        }
    }

    /// Shiny specular pops at the back-wall corners.
    private func drawGlossyCorners(ctx: inout GraphicsContext, back: CGRect) {
        for p in corners(back) {
            let glowRect = CGRect(x: p.x - 22, y: p.y - 22, width: 44, height: 44)
            ctx.fill(
                Path(ellipseIn: glowRect),
                with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.85), accent.opacity(0.4), .clear]),
                    center: p, startRadius: 0, endRadius: 22
                )
            )
        }
    }
}

/// Lightweight device-tilt provider for the parallax effect. Normalized
/// roll/pitch, smoothed, in the range of roughly -1...1.
private final class SplashMotion: ObservableObject {

    @Published var offset: CGPoint = .zero

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let d = data else { return }
            let x = CGFloat(max(-1, min(1, d.attitude.roll / (.pi / 4))))
            let y = CGFloat(max(-1, min(1, d.attitude.pitch / (.pi / 4))))
            // Low-pass smoothing to avoid jitter
            self.offset = CGPoint(
                x: self.offset.x + (x - self.offset.x) * 0.15,
                y: self.offset.y + (y - self.offset.y) * 0.15
            )
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
#endif
