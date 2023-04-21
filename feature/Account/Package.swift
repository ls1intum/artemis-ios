// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Account",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Account",
            targets: ["Account"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ls1intum/artemis-ios-core-modules", .upToNextMajor(from: "0.1.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Account",
            dependencies: [
                .product(name: "APIClient", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "DesignLibrary", package: "artemis-ios-core-modules"),
                .product(name: "UserStore", package: "artemis-ios-core-modules"),
                .product(name: "PushNotifications", package: "artemis-ios-core-modules")
            ]),
        .testTarget(
            name: "AccountTests",
            dependencies: ["Account"])
    ]
)
