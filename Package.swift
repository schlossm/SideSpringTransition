// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "MSTransition",
    platforms: [.iOS(.v14), .tvOS(.v14)],
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
