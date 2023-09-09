// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "GameSync",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "GameSync",
            targets: ["GameSync"]),
    ],
    targets: [
        .target(
            name: "GameSync",
            dependencies: []),
        .testTarget(
            name: "GameSyncTests",
            dependencies: ["GameSync"]),
    ]
)
