// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ArtemisKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ArtemisKit",
            targets: [
                "ArtemisKit"
            ])
    ],
    dependencies: [
        // Starscream 4.0.6 does not build
        .package(url: "https://github.com/daltoniam/Starscream.git", exact: "4.0.4"),
        .package(url: "https://github.com/Kelvas09/EmojiPicker.git", from: "1.0.0"),
        .package(url: "https://github.com/ls1intum/apollon-ios-module", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/ls1intum/artemis-ios-core-modules", .upToNextMajor(from: "14.0.0")),
        .package(url: "https://github.com/mac-cain13/R.swift.git", from: "7.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ArtemisKit",
            dependencies: [
                "CourseRegistration",
                "CourseView",
                "Dashboard",
                "Messages",
                "Navigation",
                "Notifications",
                .product(name: "Login", package: "artemis-ios-core-modules")
            ]),
        .target(
            name: "CourseRegistration",
            dependencies: [
                .product(name: "APIClient", package: "artemis-ios-core-modules"),
                .product(name: "DesignLibrary", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "RswiftLibrary", package: "R.swift")
            ],
            plugins: [
                .plugin(name: "RswiftGeneratePublicResources", package: "R.swift")
            ]),
        .target(
            name: "CourseView",
            dependencies: [
                "Messages",
                "Navigation",
                .product(name: "ApollonEdit", package: "apollon-ios-module"),
                .product(name: "ApollonView", package: "apollon-ios-module"),
                .product(name: "ApollonShared", package: "apollon-ios-module"),
                .product(name: "APIClient", package: "artemis-ios-core-modules"),
                .product(name: "ArtemisMarkdown", package: "artemis-ios-core-modules"),
                .product(name: "Common", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "SharedServices", package: "artemis-ios-core-modules"),
                .product(name: "UserStore", package: "artemis-ios-core-modules"),
                .product(name: "RswiftLibrary", package: "R.swift")
            ],
            plugins: [
                .plugin(name: "RswiftGeneratePublicResources", package: "R.swift")
            ]),
        .target(
            name: "Dashboard",
            dependencies: [
                "CourseRegistration",
                "CourseView",
                "Navigation",
                "Notifications",
                .product(name: "Account", package: "artemis-ios-core-modules"),
                .product(name: "APIClient", package: "artemis-ios-core-modules"),
                .product(name: "DesignLibrary", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "SharedServices", package: "artemis-ios-core-modules"),
                .product(name: "RswiftLibrary", package: "R.swift")
            ],
            plugins: [
                .plugin(name: "RswiftGeneratePublicResources", package: "R.swift")
            ]),
        .target(
            name: "Extensions",
            dependencies: [
                .product(name: "Common", package: "artemis-ios-core-modules")
            ]),
        .target(
            name: "Messages",
            dependencies: [
                "Extensions",
                "Navigation",
                .product(name: "EmojiPicker", package: "EmojiPicker"),
                .product(name: "APIClient", package: "artemis-ios-core-modules"),
                .product(name: "ArtemisMarkdown", package: "artemis-ios-core-modules"),
                .product(name: "DesignLibrary", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "SharedServices", package: "artemis-ios-core-modules"),
                .product(name: "UserStore", package: "artemis-ios-core-modules"),
                .product(name: "RswiftLibrary", package: "R.swift")
            ],
            plugins: [
                .plugin(name: "RswiftGeneratePublicResources", package: "R.swift")
            ]),
        .target(
            name: "Navigation",
            dependencies: [
                "Extensions",
                .product(name: "Common", package: "artemis-ios-core-modules"),
                .product(name: "SharedModels", package: "artemis-ios-core-modules"),
                .product(name: "SharedServices", package: "artemis-ios-core-modules"),
                .product(name: "UserStore", package: "artemis-ios-core-modules")
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
                .product(name: "RswiftLibrary", package: "R.swift")
            ],
            plugins: [
                .plugin(name: "RswiftGeneratePublicResources", package: "R.swift")
            ]),
        .testTarget(
            name: "ArtemisKitTests",
            dependencies: [
                "Messages"
            ])
    ]
)
