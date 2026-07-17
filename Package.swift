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
        // Pin to the Cache commit that includes WebAssembly `canImport(Combine)` guards and the
        // Linux/WASI collection-cast fix from 0xLeif/Cache#30. Switch back to a versioned
        // `from:` pin once that PR is merged and tagged (e.g. 2.1.3+).
        .package(
            url: "https://github.com/0xLeif/Cache",
            revision: "33ef0d77e144eaab0734b3da02c3fed6629166eb"
        ),
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
            ] + strictSwiftSettings
        ),
        .testTarget(
            name: "AppStateTests",
            dependencies: ["AppState"],
            swiftSettings: strictSwiftSettings
        )
    ],
    swiftLanguageModes: [.v6]
)
