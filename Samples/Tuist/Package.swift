// swift-tools-version: 5.9

import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "KeyboardObserver": .framework,
        "Logging": .framework,
        "Modals": .framework,
        "ViewEnvironment": .framework,
        "ViewEnvironmentUI": .framework,
        "Workflow": .framework,
        "WorkflowModals": .framework,
        "WorkflowUI": .framework,
        "ReactiveSwift": .framework,
    ]
)
#endif

let package = Package(
    name: "Development",
    dependencies: [
        .package(path: "../../"),
    ]
)
