// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Features",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Features", targets: ["Features"])
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../Networking")
    ],
    targets: [
        .target(
            name: "Features",
            dependencies: ["DesignSystem", "Networking"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
