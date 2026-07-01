import SwiftUI
import RealityKit

/// Visual identity for a ``DicyaninSplashView``.
///
/// The default theme reproduces the original DicyaninLabs cyber-green look. Override any
/// field to re-skin the splash for another app. Typography flows through `fontName`
/// (a bundled PostScript font name in the *host app's* main bundle); set it to `nil` to
/// fall back to the system monospaced font.
public struct SplashTheme: Sendable {
    public var accent: Color
    public var accentUIColor: UIColor
    public var alert: Color
    public var background: Color
    public var fontName: String?

    public init(
        accent: Color = Color(red: 0.02, green: 1.0, blue: 0.38),
        accentUIColor: UIColor = UIColor(red: 0.02, green: 1.0, blue: 0.38, alpha: 1),
        alert: Color = Color(red: 1.0, green: 0.1, blue: 0.2),
        background: Color = Color(red: 0.02, green: 0.02, blue: 0.03),
        fontName: String? = nil
    ) {
        self.accent = accent
        self.accentUIColor = accentUIColor
        self.alert = alert
        self.background = background
        self.fontName = fontName
    }

    public static let cyberGreen = SplashTheme()

    // MARK: - Typography

    /// SwiftUI font flowing through `fontName`.
    public func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let name = fontName { return .custom(name, fixedSize: size) }
        return .system(size: size, weight: weight, design: .monospaced)
    }

    /// UIKit font for RealityKit 3D text and anywhere a `UIFont` is required.
    public func uiFont(_ size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        if let name = fontName, let f = UIFont(name: name, size: size) { return f }
        return .monospacedSystemFont(ofSize: size, weight: weight)
    }
}
