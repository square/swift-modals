// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Modals",
    defaultLocalization: "en",
    platforms: [
        .macCatalyst(.v16),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "Modals",
            targets: ["Modals"]
        ),
        .library(
            name: "WorkflowModals",
            targets: ["WorkflowModals"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.4.4"),
        .package(url: "https://github.com/square/swift-keyboard-observer", from: "1.1.0"),
        .package(url: "https://github.com/square/workflow-swift", "4.0.1"..<"6.0.0"),
    ],
    targets: [
        .target(
            name: "Modals",
            dependencies: [
                .product(name: "KeyboardObserver", package: "swift-keyboard-observer"),
                .product(name: "ViewEnvironmentUI", package: "workflow-swift"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Modals",
            exclude: ["Tests"],
            sources: ["Sources"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "WorkflowModals",
            dependencies: [
                .target(name: "Modals"),
                .product(name: "WorkflowUI", package: "workflow-swift"),
            ],
            path: "WorkflowModals",
            exclude: ["Tests"],
            sources: ["Sources"]
        ),
    ]
)
