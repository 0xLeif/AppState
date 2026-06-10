// swift-tools-version: 6.0

import Foundation
import PackageDescription

// Opt-in strict build, used by CI only. Treats warnings as errors for *our* targets without
// forcing the flag onto dependencies (e.g. Cache) or onto downstream consumers — `unsafeFlags`
// would otherwise make AppState unusable as a dependency. Enabled when `APPSTATE_STRICT` is set.
let strictSwiftSettings: [SwiftSetting] = ProcessInfo.processInfo.environment["APPSTATE_STRICT"] != nil
    ? [.unsafeFlags(["-warnings-as-errors"])]
    : []

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
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0"),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "AppState",
            dependencies: [
                "Cache"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ] + strictSwiftSettings
        ),
        .testTarget(
            name: "AppStateTests",
            dependencies: [
                "AppState",
                .product(name: "ViewInspector", package: "ViewInspector")
            ],
            swiftSettings: strictSwiftSettings
        )
    ],
    swiftLanguageModes: [.v6]
)
