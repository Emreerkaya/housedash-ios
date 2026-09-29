// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Features",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Features", targets: ["Features"])
    ],
    dependencies: [
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "Features",
            dependencies: ["DesignSystem"],
            resources: [.process("Resources/ProblemPhotos.xcassets")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features"],
            resources: [
                .copy("Resources/i7-corpus.tsv"),
                .process("Resources/TestPhotos.xcassets")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
