// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DataDashboard",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "DataDashboard",
            targets: ["DataDashboard"]
        ),
    ],
    dependencies: [
        .package(path: "../../.."),
    ],
    targets: [
        .target(
            name: "DataDashboard",
            dependencies: [
                .product(name: "AppState", package: "AppState"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "DataDashboardTests",
            dependencies: [
                "DataDashboard",
                .product(name: "AppState", package: "AppState"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
    ]
)
