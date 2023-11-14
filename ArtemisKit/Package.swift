// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ArtemisKit",
    defaultLocalization: "en_US",
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
        .package(url: "https://github.com/Kelvas09/EmojiPicker.git", from: "1.0.0"),
        .package(url: "https://github.com/ls1intum/artemis-ios-core-modules", .upToNextMajor(from: "7.0.0")),
        .package(url: "https://github.com/mac-cain13/R.swift.git", from: "7.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Messages",
            dependencies: [
                "EmojiPicker",
                "Navigation",
                .product(name: "APIClient", package: "artemis-ios-core-modules"),
                .product(name: "ArtemisMarkdown", package: "artemis-ios-core-modules"),
                .product(name: "DesignLibrary", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "SharedServices", package: "artemis-ios-core-modules"),
                .product(name: "UserStore", package: "artemis-ios-core-modules"),
                .product(name: "RswiftLibrary", package: "R.swift"),
            ],
            plugins: [
                .plugin(name: "RswiftGeneratePublicResources", package: "R.swift"),
            ]),
        .target(
            name: "Navigation",
            dependencies: [
                .product(name: "Common", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "UserStore", package: "artemis-ios-core-modules"),
            ]),
        .target(
            name: "Notifications",
            dependencies: [
                "Navigation",
                .product(name: "APIClient", package: "artemis-ios-core-modules"),
                .product(name: "DesignLibrary", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "PushNotifications", package: "artemis-ios-core-modules"),
                .product(name: "UserStore", package: "artemis-ios-core-modules"),
                .product(name: "RswiftLibrary", package: "R.swift"),
            ],
            plugins: [
                .plugin(name: "RswiftGeneratePublicResources", package: "R.swift"),
            ]),
        .testTarget(
            name: "ArtemisKitTests",
            dependencies: []),
    ]
)
