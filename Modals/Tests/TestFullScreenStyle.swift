import Modals
import ViewEnvironment

struct TestFullScreenStyle: ModalPresentationStyle {

    var identifier: String? = nil
    var viewControllerContainmentPreferences: ModalBehaviorPreferences.ViewControllerContainmentPreferences = .default
    var environmentCustomization: (inout ViewEnvironment) -> Void = { _ in }

    func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
        ModalBehaviorPreferences(
            usesPreferredContentSize: false,
            viewControllerContainmentPreferences: viewControllerContainmentPreferences
        )
    }

    func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
        ModalDisplayValues(frame: context.containerCoordinateSpace.bounds)
    }

    func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(frame: context.containerCoordinateSpace.bounds)
    }

    func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(frame: context.containerCoordinateSpace.bounds)
    }

    func customize(environment: inout ViewEnvironment) {
        environmentCustomization(&environment)
    }
}


extension ModalPresentationStyleProvider {

    static func testFull(
        viewControllerContainmentPreferences: ModalBehaviorPreferences.ViewControllerContainmentPreferences = .default,
        environmentCustomization: @escaping (inout ViewEnvironment) -> Void = { _ in }
    ) -> Self {
        .init { environment in
            TestFullScreenStyle(
                viewControllerContainmentPreferences: viewControllerContainmentPreferences,
                environmentCustomization: environmentCustomization
            )
        }
    }
}
