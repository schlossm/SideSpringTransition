// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MSTransition",
    platforms: [.iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "MSTransition",
            targets: ["MSTransition"]),
    ],
    targets: [
        .target(
            name: "MSTransition",
            dependencies: [])
    ]
)
