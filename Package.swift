// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppState",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "AppState",
            targets: ["AppState"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/0xLeif/Cache", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "AppState",
            dependencies: [
                "Cache"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "AppStateTests",
            dependencies: ["AppState"]
        )
    ],
    swiftLanguageModes: [.v6]
)
