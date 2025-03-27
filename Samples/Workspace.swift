import ProjectDescription
import ProjectDescriptionHelpers

let workspace = Workspace(
    name: "ModalsDevelopment",
    projects: ["."],
    schemes: [
        // Generate a scheme for each target in Package.swift for convenience
        .modals("Modals"),
        .modals("WorkflowModals"),
    ]
)

extension Scheme {
    public static func modals(_ target: String) -> Self {
        .scheme(
            name: target,
            buildAction: .buildAction(targets: [.project(path: "..", target: target)])
        )
    }
}
