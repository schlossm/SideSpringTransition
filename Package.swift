// swift-tools-version:6.0

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
            dependencies: []),
        .testTarget(name: "MSTransitionTests",
                    dependencies: ["MSTransition"])
    ]
)
