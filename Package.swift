// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TaskManager",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TaskManager",
            targets: ["TaskManager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/shakurocom/CommonTypes.git", from: "1.9.6"),
    ],
    targets: [
        .target(
            name: "TaskManager",
            dependencies: [
                .product(name: "CommonTypes", package: "CommonTypes"),
            ],
            path: "Source"),
    ]
)
