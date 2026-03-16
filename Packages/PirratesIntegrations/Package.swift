// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PirratesIntegrations",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "PirratesIntegrations", targets: ["PirratesIntegrations"]),
    ],
    dependencies: [
        .package(path: "../PirratesCore"),
    ],
    targets: [
        .target(
            name: "PirratesIntegrations",
            dependencies: [
                "PirratesCore",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "PirratesIntegrationsTests",
            dependencies: [
                "PirratesIntegrations",
                "PirratesCore",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
