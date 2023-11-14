// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ArtemisKit",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ArtemisKit",
            targets: [
                "Navigation",
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/ls1intum/artemis-ios-core-modules", .upToNextMajor(from: "7.0.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Navigation",
            dependencies: [
                .product(name: "Common", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "UserStore", package: "artemis-ios-core-modules"),
            ]),
        .testTarget(
            name: "ArtemisKitTests",
            dependencies: []),
    ]
)
