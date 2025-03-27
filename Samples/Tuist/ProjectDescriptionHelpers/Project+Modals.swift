import Foundation
import ProjectDescription

public let modalsBundleIdPrefix = "com.squareup.modals"
public let modalsDestinations: ProjectDescription.Destinations = .iOS
public let modalsDeploymentTargets: DeploymentTargets = .iOS("16.0")

extension Target {
    public static func app(
        name: String,
        sources: ProjectDescription.SourceFilesList,
        resources: ProjectDescription.ResourceFileElements? = nil,
        dependencies: [TargetDependency] = []
    ) -> Self {
        .target(
            name: name,
            destinations: modalsDestinations,
            product: .app,
            bundleId: "\(modalsBundleIdPrefix).\(name)",
            deploymentTargets: modalsDeploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": ["UIColorName": ""],
                ]
            ),
            sources: sources,
            resources: resources,
            dependencies: dependencies
        )
    }

    public static func target(
        name: String,
        sources: ProjectDescription.SourceFilesList? = nil,
        resources: ProjectDescription.ResourceFileElements? = nil,
        dependencies: [TargetDependency] = []
    ) -> Self {
        .target(
            name: name,
            destinations: modalsDestinations,
            product: .framework,
            bundleId: "\(modalsBundleIdPrefix).\(name)",
            deploymentTargets: modalsDeploymentTargets,
            sources: sources ?? "\(name)/Sources/**",
            resources: resources,
            dependencies: dependencies
        )
    }

    public static func unitTest(
        for moduleUnderTest: String,
        testName: String = "Tests",
        sources: ProjectDescription.SourceFilesList? = nil,
        dependencies: [TargetDependency] = [],
        environmentVariables: [String: EnvironmentVariable] = [:]
    ) -> Self {
        let name = "\(moduleUnderTest)-\(testName)"
        return .target(
            name: name,
            destinations: modalsDestinations,
            product: .unitTests,
            bundleId: "\(modalsBundleIdPrefix).\(name)",
            deploymentTargets: modalsDeploymentTargets,
            sources: sources ?? "../\(moduleUnderTest)/\(testName)/**",
            dependencies: [.external(name: moduleUnderTest)] + dependencies,
            environmentVariables: environmentVariables
        )
    }
}
