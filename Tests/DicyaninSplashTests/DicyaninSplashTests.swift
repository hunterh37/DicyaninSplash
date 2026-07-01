import XCTest
@testable import DicyaninSplash

final class DicyaninSplashTests: XCTestCase {
    func testDefaultThemeFontFallsBackToMonospaced() {
        let theme = SplashTheme(fontName: nil)
        _ = theme.font(20)
        _ = theme.uiFont(20)
    }

    func testConfigurationDefaults() {
        let config = SplashConfiguration(studioName: "DicyaninLabs")
        XCTAssertEqual(config.studioName, "DicyaninLabs")
        XCTAssertEqual(config.titlePhaseDuration, .milliseconds(5000))
        XCTAssertNil(config.logoSceneBuilder)
    }
}
