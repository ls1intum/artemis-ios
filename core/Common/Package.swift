// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Common",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Common",
            targets: ["Common"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", exact: "6.5.0"),
        .package(url: "https://github.com/hmlongco/Factory", exact: "1.2.8"),
        .package(url: "https://github.com/malcommac/SwiftDate", exact: "7.0.0"),
        .package(url: "https://github.com/CombineCommunity/RxCombine.git", exact: "2.0.1"),
        .package(url: "https://github.com/RxSwiftCommunity/RxSwiftExt", exact: "6.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Common",
            dependencies: ["RxSwift", "Factory", "SwiftDate", "RxCombine", "RxSwiftExt"]),
        .testTarget(
            name: "CommonTests",
            dependencies: ["Common"]),
    ]
)
