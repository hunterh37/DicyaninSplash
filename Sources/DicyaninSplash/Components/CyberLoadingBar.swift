import SwiftUI

/// Cyber-styled determinate loading bar with a scanline shimmer and percentage readout.
public struct CyberLoadingBar: View {
    public var progress: Double   // 0.0 ... 1.0
    public var label: String
    public var theme: SplashTheme

    public init(progress: Double, label: String, theme: SplashTheme = .cyberGreen) {
        self.progress = progress
        self.label = label
        self.theme = theme
    }

    private var clamped: CGFloat { CGFloat(max(0, min(1, progress))) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accent.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(theme.accent.opacity(0.35), lineWidth: 1)
                        )

                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accent)
                        .shadow(color: theme.accent.opacity(0.8), radius: 6)
                        .frame(width: geo.size.width * clamped)
                        .animation(.linear(duration: 0.2), value: progress)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.08), .clear, .white.opacity(0.04)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: geo.size.width * clamped)
                        .animation(.linear(duration: 0.2), value: progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text(label)
                    .font(theme.font(36, weight: .bold))
                    .kerning(4)
                    .foregroundStyle(theme.accent)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(theme.font(36, weight: .bold))
                    .foregroundStyle(theme.accent)
                    .animation(.linear(duration: 0.2), value: progress)
            }
        }
    }
}
