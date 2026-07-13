// Cross-platform shims so the package's UIKit-flavoured API (UIColor / UIFont)
// compiles unchanged on macOS, where the equivalents live in AppKit.
//
// The default `SplashConfiguration` only drives the SwiftUI splash (glitch title +
// loading bar); the RealityKit helpers that reference these types are still compiled
// as part of the target, so the aliases keep the whole module building on macOS.

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

public typealias UIColor = NSColor
public typealias UIFont = NSFont
#endif
