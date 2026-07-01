import SwiftUI

/// Brushed-chrome + RGB-split glitch treatment applied to any masking shape (typically text).
public struct MatrixGlitchChrome<Mask: View>: View {
    public var size: CGFloat
    public var glow: Bool
    public var theme: SplashTheme
    @ViewBuilder public var mask: () -> Mask

    public init(
        size: CGFloat = 120,
        glow: Bool = true,
        theme: SplashTheme = .cyberGreen,
        @ViewBuilder mask: @escaping () -> Mask
    ) {
        self.size = size
        self.glow = glow
        self.theme = theme
        self.mask = mask
    }

    public var body: some View {
        TimelineView(.animation) { tl in
            content(tl.date.timeIntervalSinceReferenceDate)
        }
    }

    private func content(_ t: Double) -> some View {
        let phase = t.truncatingRemainder(dividingBy: 2.4)
        let glitching = phase < 0.22
        let jitter = glitching ? CGFloat(sin(t * 90)) * size * 0.05 : 0

        return ZStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(white: 0.08),
                        Color(red: 0.0, green: 0.4, blue: 0.18),
                        Color(white: 0.9),
                        Color(red: 0.0, green: 0.3, blue: 0.12),
                        Color(white: 0.06)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                BrushedNoise(angle: .degrees(90))
                    .blendMode(.overlay).opacity(0.4)
            }
            .mask(mask())

            mask().foregroundStyle(Color(red: 1, green: 0, blue: 0.2))
                .offset(x: -jitter).blendMode(.screen).opacity(glitching ? 0.9 : 0.0)
            mask().foregroundStyle(Color(red: 0, green: 1, blue: 0.4))
                .offset(x: jitter * 0.6).blendMode(.screen).opacity(glitching ? 0.9 : 0.0)
            mask().foregroundStyle(Color(red: 0.2, green: 0.4, blue: 1))
                .offset(x: jitter).blendMode(.screen).opacity(glitching ? 0.9 : 0.0)

            ScanlinePattern(spacing: 3)
                .blendMode(.multiply).opacity(0.5)
                .mask(mask())

            if glitching {
                Rectangle()
                    .fill(theme.accent.opacity(0.5))
                    .frame(height: size * 0.12)
                    .offset(y: CGFloat(sin(t * 17)) * size * 0.3)
                    .blendMode(.screen)
                    .mask(mask())
            }
        }
        .compositingGroup()
        .shadow(color: glow ? theme.accent.opacity(0.9) : .clear, radius: glow ? 10 : 0)
        .shadow(color: glow ? theme.accent.opacity(0.5) : .clear, radius: glow ? 22 : 0)
    }
}

/// Procedural brushed-metal striations rendered in a Canvas.
private struct BrushedNoise: View {
    var angle: Angle = .degrees(90)

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: 9173)
            let count = 90
            for _ in 0..<count {
                let x = CGFloat(rng.nextUnit()) * size.width
                let w = CGFloat(0.4 + rng.nextUnit() * 1.4)
                let gray = 0.35 + rng.nextUnit() * 0.6
                let rect = CGRect(x: x, y: -size.height, width: w, height: size.height * 3)
                ctx.fill(Path(rect), with: .color(Color(white: gray, opacity: 0.5)))
            }
        }
        .rotationEffect(angle - .degrees(90))
        .scaleEffect(1.6)
    }
}

private struct ScanlinePattern: View {
    var spacing: CGFloat = 3
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                         with: .color(.black.opacity(0.6)))
                y += spacing
            }
        }
    }
}

/// Tiny deterministic RNG so brushed striations don't reshuffle every frame.
private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state >> 12; state ^= state << 25; state ^= state >> 27
        return state &* 0x2545F4914F6CDD1D
    }
    mutating func nextUnit() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }
}
