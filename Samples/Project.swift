import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "ModalsDevelopment",
    settings: .settings(base: ["ENABLE_MODULE_VERIFIER": "YES"]),
    targets: [

        .target(
            name: "ExampleStyles",
            sources: "ExampleStyles/Sources/**",
            dependencies: [
                .external(name: "Modals"),
            ]
        ),

        .app(
            name: "UIKitApp",
            sources: "UIKitApp/Sources/**",
            dependencies: [
                .target(name: "ExampleStyles"),
                .external(name: "Modals"),
            ]
        ),

        .app(
            name: "WorkflowApp",
            sources: "WorkflowApp/Sources/**",
            dependencies: [
                .target(name: "ExampleStyles"),
                .external(name: "WorkflowModals"),
            ]
        ),

        .target(
            name: "TestingSupport",
            sources: "../TestingSupport/Sources/**",
            dependencies: [
                .external(name: "Modals"),
                .xctest,
            ]
        ),
        .app(
            name: "TestAppHost",
            sources: "../TestingSupport/AppHost/Sources/**",
            dependencies: [
                .external(name: "Modals"),
                .external(name: "Logging"),
            ]
        ),

        .unitTest(
            for: "Modals",
            dependencies: [
                .target(name: "TestingSupport"),
                .target(name: "TestAppHost"),
            ]
        ),
        .unitTest(
            for: "WorkflowModals",
            dependencies: [
                .external(name: "WorkflowCombine"),
                .target(name: "TestingSupport"),
                .target(name: "TestAppHost"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "UnitTests",
            testAction: .targets(
                [
                    "Modals-Tests",
                    "WorkflowModals-Tests",
                ]
            )
        ),
        .scheme(
            name: "Samples",
            buildAction: .buildAction(
                targets: [
                    "WorkflowApp",
                ]
            )
        ),
    ]
)
