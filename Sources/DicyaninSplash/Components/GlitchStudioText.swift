import SwiftUI

/// Extruded, chromatic-aberration "blocky" studio title with an RGB-split glitch state.
/// Reusable for any studio / brand name shown during a splash.
public struct GlitchStudioText: View {
    public var text: String
    public var glitching: Bool
    public var fontSize: CGFloat
    public var theme: SplashTheme

    private let depth = 6

    public init(
        _ text: String,
        glitching: Bool = false,
        fontSize: CGFloat = 84,
        theme: SplashTheme = .cyberGreen
    ) {
        self.text = text
        self.glitching = glitching
        self.fontSize = fontSize
        self.theme = theme
    }

    private var blockFont: Font { theme.font(fontSize, weight: .black).lowercaseSmallCaps() }

    public var body: some View {
        ZStack {
            ForEach(1..<depth, id: \.self) { i in
                Text(text)
                    .font(blockFont)
                    .foregroundStyle(shadowColor(layer: i))
                    .offset(x: CGFloat(i) * 1.6, y: CGFloat(i) * 1.6)
            }

            let redShift: CGFloat = glitching ? CGFloat.random(in: -28 ... -16) : -7
            let blueShift: CGFloat = glitching ? CGFloat.random(in: 16...28) : 7
            let jitterY: CGFloat = glitching ? CGFloat.random(in: -6...6) : 0

            Text(text)
                .font(blockFont)
                .foregroundStyle(Color.red.opacity(glitching ? 0.95 : 0.7))
                .offset(x: redShift, y: jitterY)
                .blendMode(.screen)
                .blur(radius: glitching ? 1.2 : 0.6)

            Text(text)
                .font(blockFont)
                .foregroundStyle(Color.green.opacity(glitching ? 0.7 : 0.45))
                .offset(x: glitching ? CGFloat.random(in: -6...6) : 0, y: -jitterY)
                .blendMode(.screen)

            Text(text)
                .font(blockFont)
                .foregroundStyle(Color.cyan.opacity(glitching ? 0.9 : 0.65))
                .offset(x: blueShift, y: -jitterY)
                .blendMode(.screen)
                .blur(radius: glitching ? 1.2 : 0.6)

            MatrixGlitchChrome(size: fontSize, theme: theme) {
                Text(text).font(blockFont)
            }
            .offset(
                x: glitching ? CGFloat.random(in: -4...4) : 0,
                y: glitching ? CGFloat.random(in: -2...2) : 0
            )
            .opacity(glitching ? Double.random(in: 0.6...1.0) : 1.0)
        }
        .shadow(color: .black.opacity(0.5), radius: 12, x: 4, y: 8)
        .animation(glitching ? .none : .easeOut(duration: 0.08), value: glitching)
    }

    private func shadowColor(layer: Int) -> Color {
        let t = Double(layer) / Double(depth)
        return Color(
            red: 0.08 + 0.04 * (1 - t),
            green: 0.08 + 0.04 * (1 - t),
            blue: 0.12 + 0.06 * (1 - t)
        )
    }
}
