import SwiftUI
import RealityKit

/// Drop-in two-phase launch splash, generalised from the original DicyaninLabs ZombieShooter
/// splash. Phase 1 shows a glitchy 3D studio title (with an optional 3D backdrop); phase 2
/// crossfades to a logo centrepiece + cyber loading bar driven by injected preload progress.
/// When loading completes the view calls `onFinished` so the host can hand off to its menu.
///
/// The package owns no assets, windows, or immersive spaces: feed all of that in via
/// ``SplashConfiguration`` and react in `onFinished`.
public struct DicyaninSplashView: View {
    private let configuration: SplashConfiguration
    private let onFinished: () -> Void

    @State private var loadProgress: Double = 0
    @State private var loadLabel: String = "INITIALIZING..."
    @State private var logoPhase = false
    @State private var textAppear = false
    @State private var logoAppear = false
    @State private var glitching = false

    public init(configuration: SplashConfiguration, onFinished: @escaping () -> Void) {
        self.configuration = configuration
        self.onFinished = onFinished
    }

    private var theme: SplashTheme { configuration.theme }

    public var body: some View {
        ZStack {
            // Phase 2 — logo centrepiece + loading bar
            VStack(spacing: 0) {
                Spacer()

                if let builder = configuration.logoSceneBuilder {
                    SplashEntityScene(builder: { await builder(theme) })
                        .frame(maxWidth: 780, maxHeight: 320)
                        .padding(.bottom, 120)
                }

                CyberLoadingBar(progress: loadProgress, label: loadLabel, theme: theme)
                    .frame(width: 700)
                    .padding(.bottom, 112)
                    .padding(.horizontal, 20)
            }
            .opacity(logoAppear ? 1 : 0)
            .scaleEffect(logoAppear ? 1 : 0.88)
            .animation(.easeOut(duration: 0.6), value: logoAppear)

            // Phase 1 — optional 3D backdrop behind the studio title
            if let builder = configuration.titleSceneBuilder {
                SplashEntityScene(builder: { await builder(theme) })
                    .frame(width: 360, height: 360)
                    .opacity(textAppear && !logoPhase ? 1 : 0)
                    .animation(.easeIn(duration: 0.35), value: logoPhase)
            }

            // Phase 1 — glitchy studio title
            GlitchStudioText(configuration.studioName, glitching: glitching, theme: theme)
                .opacity(textAppear && !logoPhase ? 1 : 0)
                .scaleEffect(textAppear && !logoPhase ? 1 : 0.92)
                .animation(.easeOut(duration: 0.45), value: textAppear)
                .animation(.easeIn(duration: 0.35), value: logoPhase)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { textAppear = true }
        }
        .task { await runGlitch() }
        .task { await runSequence() }
    }

    @MainActor
    private func runSequence() async {
        try? await Task.sleep(for: configuration.titlePhaseDuration)
        logoPhase = true
        try? await Task.sleep(for: configuration.logoFadeInDelay)
        withAnimation { logoAppear = true }

        var reported = false
        await configuration.preload { p, label in
            reported = true
            loadProgress = p
            loadLabel = label
        }

        // If the host's preload never reported progress, run a synthetic sweep so the bar
        // still fills before handoff.
        if !reported {
            let steps = 30
            let per = configuration.syntheticLoadDuration / steps
            loadLabel = "LOADING..."
            for i in 1...steps {
                loadProgress = Double(i) / Double(steps)
                try? await Task.sleep(for: per)
            }
        }

        try? await Task.sleep(for: .milliseconds(600))
        onFinished()
    }

    @MainActor
    private func runGlitch() async {
        try? await Task.sleep(for: .milliseconds(150))
        for _ in 0..<4 {
            glitching = true
            try? await Task.sleep(for: .milliseconds(Int.random(in: 60...100)))
            glitching = false
            try? await Task.sleep(for: .milliseconds(Int.random(in: 50...130)))
        }
    }
}

/// Hosts a caller-built RealityKit `Entity` in a transparent `RealityView`.
struct SplashEntityScene: View {
    let builder: () async -> Entity

    var body: some View {
        RealityView { content in
            content.add(await builder())
        }
    }
}
