// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Notifications",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Notifications",
            targets: ["Notifications"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(path: "../../core/APIClient"),
        .package(path: "../../core/SharedModels"),
        .package(path: "../../core/DesignLibrary"),
        .package(path: "../../core/Navigation"),
        .package(url: "https://github.com/mac-cain13/R.swift.git", from: "7.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Notifications",
            dependencies: ["APIClient", "SharedModels", "DesignLibrary", "Navigation", .product(name: "RswiftLibrary", package: "R.swift")],
            plugins: [.plugin(name: "RswiftGeneratePublicResources", package: "R.swift")]
        ),
        .testTarget(
            name: "NotificationsTests",
            dependencies: ["Notifications"]),
    ]
)
