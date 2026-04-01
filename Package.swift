// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-network",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "SPFKNetwork",
            targets: ["SPFKNetwork"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-utils", from: "0.0.1"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "0.0.9"),
    ],
    targets: [
        .target(
            name: "SPFKNetwork",
            dependencies: [
                .product(name: "SPFKUtils", package: "spfk-utils"),
            ]
        ),
        .testTarget(
            name: "SPFKNetworkTests",
            dependencies: [
                "SPFKNetwork",
                .product(name: "SPFKTesting", package: "spfk-testing"),
            ]
        ),
    ]
)
