// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftDataExample",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    dependencies: [
        .package(name: "AppState", path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "SwiftDataExample",
            dependencies: [
                .product(name: "AppState", package: "AppState")
            ]
        )
    ]
)
