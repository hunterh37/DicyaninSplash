// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DicyaninSplash",
    platforms: [
        .visionOS(.v2),
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "DicyaninSplash",
            targets: ["DicyaninSplash"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/praeclarum/ShaderGraphCoder", exact: "2.0.0")
    ],
    targets: [
        .target(
            name: "DicyaninSplash",
            dependencies: ["ShaderGraphCoder"]
        ),
        .testTarget(
            name: "DicyaninSplashTests",
            dependencies: ["DicyaninSplash"]
        )
    ]
)
