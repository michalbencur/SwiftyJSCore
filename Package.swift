// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyJSCore",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
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
            dependencies: []),
        .testTarget(
            name: "SwiftyJSCoreTests",
            dependencies: ["SwiftyJSCore"],
            resources: [.process("script.js")]),
    ]
)
