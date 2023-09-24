// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Messages",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Messages",
            targets: ["Messages"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ls1intum/artemis-ios-core-modules", branch: "feature/development/screenshots"),
        .package(path: "../../core/Navigation"),
        .package(url: "https://github.com/mac-cain13/R.swift.git", from: "7.0.0"),
        .package(url: "https://github.com/Kelvas09/EmojiPicker.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.0.0"),
        // Fix error in SwiftStomp
        .package(url: "https://github.com/daltoniam/Starscream.git", exact: "4.0.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Messages",
            dependencies: [
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "APIClient", package: "artemis-ios-core-modules"),
                .product(name: "DesignLibrary", package: "artemis-ios-core-modules"),
                .product(name: "UserStore", package: "artemis-ios-core-modules"),
                .product(name: "ArtemisMarkdown", package: "artemis-ios-core-modules"),
                .product(name: "SharedServices", package: "artemis-ios-core-modules"),
                "Navigation",
                "EmojiPicker",
                .product(name: "RswiftLibrary", package: "R.swift"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            plugins: [.plugin(name: "RswiftGeneratePublicResources", package: "R.swift")]
        ),
        .testTarget(
            name: "MessagesTests",
            dependencies: [
                "Messages",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ])
    ]
)
