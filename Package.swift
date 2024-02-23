// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AppState",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8),
        .macOS(.v11),
        .tvOS(.v15),
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
        .package(url: "https://github.com/0xLeif/Waiter", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AppState",
            dependencies: [
                "Cache"
            ]
        ),
        .testTarget(
            name: "AppStateTests",
            dependencies: [
                "AppState",
                "Waiter"
            ]
        )
    ]
)
