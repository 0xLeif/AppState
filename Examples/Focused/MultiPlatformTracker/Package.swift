// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MultiPlatformTracker",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "MultiPlatformTracker",
            targets: ["MultiPlatformTracker"]
        ),
    ],
    dependencies: [
        .package(path: "../../.."),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "MultiPlatformTracker",
            dependencies: [
                .product(name: "AppState", package: "AppState"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "MultiPlatformTrackerTests",
            dependencies: [
                "MultiPlatformTracker",
                .product(name: "AppState", package: "AppState"),
                .product(name: "ViewInspector", package: "ViewInspector"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
    ]
)
