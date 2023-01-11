// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CourseRegistration",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CourseRegistration",
            targets: ["CourseRegistration"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path: "../../core/APIClient"),
        .package(path: "../../core/UI"),
        .package(path: "../../core/Data"),
        .package(path: "../../core/Device"),
        .package(path: "../../core/Common"),
        .package(url: "https://github.com/gonzalezreal/MarkdownUI", exact: "1.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CourseRegistration",
            dependencies: ["UI", "Data", "Device", "Common", "MarkdownUI", "APIClient"]),
        .testTarget(
            name: "CourseRegistrationTests",
            dependencies: ["CourseRegistration"]),
    ]
)
