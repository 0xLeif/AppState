// swift-tools-version: 6.0

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
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0") // Version GRDB v6.26.0
    ],
    targets: [
        .target(
            name: "AppState",
            dependencies: [
                "Cache",
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        .testTarget(
            name: "AppStateTests",
            dependencies: [
                "AppState",
                .product(name: "GRDB", package: "GRDB.swift")]
        )
    ]
)
