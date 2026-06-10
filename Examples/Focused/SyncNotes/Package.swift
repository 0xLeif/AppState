// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SyncNotes",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "SyncNotes",
            targets: ["SyncNotes"]
        ),
    ],
    dependencies: [
        .package(path: "../../.."),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "SyncNotes",
            dependencies: [
                .product(name: "AppState", package: "AppState"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "SyncNotesTests",
            dependencies: [
                "SyncNotes",
                .product(name: "AppState", package: "AppState"),
                .product(name: "ViewInspector", package: "ViewInspector"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
    ]
)
