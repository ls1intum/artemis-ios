// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Dashboard",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Dashboard",
            targets: ["Dashboard"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ls1intum/artemis-ios-core-modules", .upToNextMajor(from: "1.0.0")),
        .package(path: "../../core/Navigation"),
        .package(path: "../CourseRegistration"),
        .package(path: "../Notifications"),
        .package(path: "../CourseView"),
        .package(path: "../Account"),
        .package(url: "https://github.com/mac-cain13/R.swift.git", from: "7.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Dashboard",
            dependencies: [
                .product(name: "APIClient", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "DesignLibrary", package: "artemis-ios-core-modules"),
                "CourseRegistration",
                "Navigation",
                "Notifications",
                "CourseView",
                "Account",
                .product(name: "RswiftLibrary", package: "R.swift")
            ],
            plugins: [.plugin(name: "RswiftGeneratePublicResources", package: "R.swift")]
        ),
        .testTarget(
            name: "DashboardTests",
            dependencies: ["Dashboard"])
    ]
)
