# DicyaninSplash

Reusable two-phase visionOS / iOS launch splash. The package ships no assets, windows, or
immersive spaces. All app-specific content is injected via `SplashConfiguration`.

## Flow

1. Phase 1: glitchy 3D studio title (`GlitchStudioText`) with an optional 3D backdrop.
2. Phase 2: crossfade to a logo centrepiece + `CyberLoadingBar` driven by your preload.
3. On completion, `onFinished` fires so the host hands off to its main UI.

## Window setup (visionOS) — read this first

`DicyaninSplashView` is a flat 2D SwiftUI view. On visionOS it MUST live in its own
`.windowStyle(.plain)` window. Do NOT embed it inside a `.windowStyle(.volumetric)`
window: a volumetric window sized in metres leaves the flat splash (and anything you
swap in after it) collapsed in a degenerate volume, so you get an empty glass box.

The correct pattern (proven in ZombieShooter and MechVision): the default window is the
plain splash, and your volumetric / main UI is a SEPARATE `WindowGroup` that the splash
opens via `openWindow` in `onFinished`, then dismisses itself.

```swift
import SwiftUI
import DicyaninSplash

@main
struct MyApp: App {
    static let splashWindowID = "Splash"
    static let mainVolumeID = "MainVolume"

    var body: some Scene {
        // 1. Default window = plain 2D splash.
        WindowGroup(id: Self.splashWindowID) {
            SplashScreen()
        }
        .windowStyle(.plain)
        .defaultSize(width: 700, height: 820)

        // 2. Main content = its OWN volumetric window, opened by the splash.
        WindowGroup(id: Self.mainVolumeID) {
            MainMenuView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.2, height: 0.9, depth: 0.8, in: .meters)
    }
}

struct SplashScreen: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        DicyaninSplashView(
            configuration: SplashConfiguration(
                studioName: "YourStudio",
                theme: .cyberGreen,
                logoSceneBuilder: { theme in await MyLogoScene.build(theme) },
                titleSceneBuilder: { theme in await MyBackdrop.build(theme) },  // optional
                preload: { report in
                    await MyAssetLoader.preloadAll { p, label in report(p, label) }
                }
            ),
            onFinished: {
                openWindow(id: MyApp.mainVolumeID)
                dismissWindow(id: MyApp.splashWindowID)
            }
        )
    }
}
```

On iOS there are no volumetric windows, so a single `WindowGroup` that swaps the splash
for your root view in `onFinished` (via local `@State`) is fine.

For the holographic title centrepiece, `HoloTitleView` renders a parameterised version of
the effect, and `makeWiremeshCyberGreenShader()` provides a cyber-green "rendering in"
material for any backdrop mesh.

## Components

- `DicyaninSplashView` — the splash driver.
- `SplashConfiguration` / `SplashTheme` — injection + palette/typography.
- `GlitchStudioText` — extruded chromatic-aberration studio title.
- `CyberLoadingBar` — determinate loader with scanline shimmer.
- `MatrixGlitchChrome` — brushed-chrome RGB-split treatment for any mask shape.
- `HoloTitleView` — holographic 3D title scene (scanlines, orbs, flicker lighting).
- `makeWiremeshCyberGreenShader()` — animated wireframe emissive material.
- `Entity.applyHologramMaterial(color:)` — recursive unlit hologram tint.

The host app owns immersive backdrops and window handoff; wire those in `onFinished` and
around the view.
