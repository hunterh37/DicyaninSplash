# DicyaninSplash

Reusable two-phase visionOS / iOS launch splash. The package ships no assets, windows, or
immersive spaces. All app-specific content is injected via `SplashConfiguration`.

## Flow

1. Phase 1: glitchy 3D studio title (`GlitchStudioText`) with an optional 3D backdrop.
2. Phase 2: crossfade to a logo centrepiece + `CyberLoadingBar` driven by your preload.
3. On completion, `onFinished` fires so the host hands off to its main UI.

## Usage

```swift
import DicyaninSplash

DicyaninSplashView(
    configuration: SplashConfiguration(
        studioName: "YourStudio",
        theme: .cyberGreen,
        logoSceneBuilder: { theme in
            // build your RealityKit centrepiece (e.g. a HoloTitleView entity)
            await MyLogoScene.build(theme)
        },
        titleSceneBuilder: { theme in
            await MyBackdrop.build(theme)   // optional backdrop
        },
        preload: { report in
            await MyAssetLoader.preloadAll { p, label in report(p, label) }
        }
    ),
    onFinished: {
        // open your main window / dismiss the splash
    }
)
```

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
