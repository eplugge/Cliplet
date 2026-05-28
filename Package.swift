// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cliplet",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ClipletCore", targets: ["ClipletCore"]),
        .executable(name: "Cliplet", targets: ["ClipletApp"])
    ],
    targets: [
        .target(
            name: "ClipletCore",
            dependencies: []
        ),
        .executableTarget(
            name: "ClipletApp",
            dependencies: ["ClipletCore"]
        ),
        .testTarget(
            name: "ClipletCoreTests",
            dependencies: ["ClipletCore"]
        )
    ]
)
