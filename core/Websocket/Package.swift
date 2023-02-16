// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Websocket",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Websocket",
            targets: ["Websocket"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path: "../Model"),
        .package(path: "../Device"),
        .package(url: "https://github.com/groue/Semaphore", exact: "0.0.6"),
        .package(url: "https://github.com/TimOrtel/SwiftStompClient", branch: "dc4fb4f1859cb13d8dddea3a870469e009601f11")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Websocket",
            dependencies: ["Model", "Device", "Semaphore", "SwiftStompClient"]),
        .testTarget(
            name: "WebsocketTests",
            dependencies: ["Websocket"])
    ]
)
