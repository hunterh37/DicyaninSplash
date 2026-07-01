import SwiftUI
import RealityKit

/// Drives a ``DicyaninSplashView``. All app-specific content (3D props, asset preloading,
/// immersive backdrops, window handoff) is injected here so the package stays free of any
/// game/app coupling.
public struct SplashConfiguration {
    /// Studio name rendered as the glitchy 3D block title in phase 1.
    public var studioName: String

    /// How long the studio-title phase is shown before crossfading to the logo phase.
    public var titlePhaseDuration: Duration

    /// Optional delay after the title phase before the logo/loader fades in.
    public var logoFadeInDelay: Duration

    public var theme: SplashTheme

    /// Optional async work that reports progress 0...1 with a status label while the logo
    /// phase is on screen. The loading bar reflects these callbacks. If `nil`, the bar
    /// animates a synthetic 0→1 sweep over ``syntheticLoadDuration``.
    public var preload: (@MainActor (_ progress: Double, _ label: String) -> Void) async -> Void

    /// Used only when `preload` performs no progress reporting / is the default.
    public var syntheticLoadDuration: Duration

    /// Optional 3D centrepiece for the logo phase, built into a `RealityView`. Receives the
    /// configured ``SplashTheme`` so props can match the palette.
    public var logoSceneBuilder: (@MainActor (SplashTheme) async -> Entity)?

    /// Optional 3D backdrop for the title phase (e.g. a retro TV behind the studio name).
    public var titleSceneBuilder: (@MainActor (SplashTheme) async -> Entity)?

    public init(
        studioName: String,
        titlePhaseDuration: Duration = .milliseconds(5000),
        logoFadeInDelay: Duration = .milliseconds(400),
        theme: SplashTheme = .cyberGreen,
        syntheticLoadDuration: Duration = .milliseconds(1800),
        logoSceneBuilder: (@MainActor (SplashTheme) async -> Entity)? = nil,
        titleSceneBuilder: (@MainActor (SplashTheme) async -> Entity)? = nil,
        preload: @escaping (@MainActor (_ progress: Double, _ label: String) -> Void) async -> Void = { report in
            // Default: no real work; the view runs a synthetic sweep instead.
            _ = report
        }
    ) {
        self.studioName = studioName
        self.titlePhaseDuration = titlePhaseDuration
        self.logoFadeInDelay = logoFadeInDelay
        self.theme = theme
        self.syntheticLoadDuration = syntheticLoadDuration
        self.logoSceneBuilder = logoSceneBuilder
        self.titleSceneBuilder = titleSceneBuilder
        self.preload = preload
    }
}
