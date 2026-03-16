// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PirratesDesignSystem",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "PirratesDesignSystem", targets: ["PirratesDesignSystem"]),
    ],
    dependencies: [
        .package(path: "../PirratesCore"),
    ],
    targets: [
        .target(
            name: "PirratesDesignSystem",
            dependencies: ["PirratesCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "PirratesDesignSystemTests",
            dependencies: ["PirratesDesignSystem"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
