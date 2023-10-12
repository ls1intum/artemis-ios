// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Screenshots",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Screenshots",
            targets: ["Screenshots"]),
    ],
    dependencies: [
        .package(path: "../CourseView"),
        .package(path: "../Dashboard"),
        .package(path: "../Messages"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.0.0"),
        // Fix error in SwiftStomp
        .package(url: "https://github.com/daltoniam/Starscream.git", exact: "4.0.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Screenshots",
            dependencies: [
                "CourseView",
                "Dashboard",
                "Messages",
            ],
            resources: [
                .copy("Media"),
            ]),
        .testTarget(
            name: "ScreenshotsTests",
            dependencies: [
                "CourseView",
                "Dashboard",
                "Messages",
                "Screenshots",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]),
    ]
)
