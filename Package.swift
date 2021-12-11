// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebSocketChat",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "WebSocketChat",
            targets: [
                "WebSocketChat"
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ReactiveX/RxSwift.git",
            .upToNextMajor(from: "5.1.1")
        ),
    ],
    targets: [
        .target(
            name: "WebSocketChat",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
            ]
        ),
        .testTarget(
            name: "WebSocketChatTests",
            dependencies: [
                .product(name: "RxTest", package: "RxSwift"),
                "WebSocketChat"
            ]
        ),
    ]
)
