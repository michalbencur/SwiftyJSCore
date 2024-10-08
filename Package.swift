// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyJSCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftyJSCore",
            targets: ["SwiftyJSCore"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftyJSCore",
            dependencies: [],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
            ),
        .testTarget(
            name: "SwiftyJSCoreTests",
            dependencies: ["SwiftyJSCore"],
            resources: [.process("script.js"), .process("swift-data.js")]
            ),
    ]
)
