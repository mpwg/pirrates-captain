// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PirratesCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "PirratesCore", targets: ["PirratesCore"]),
    ],
    targets: [
        .target(
            name: "PirratesCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "PirratesCoreTests",
            dependencies: ["PirratesCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
