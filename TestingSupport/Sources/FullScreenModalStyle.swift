import CoreGraphics
import Modals
import ViewEnvironment


public struct FullScreenModalStyle: ModalPresentationStyle {
    public var key: String
    public var environmentCustomization: (inout ViewEnvironment) -> Void

    public init(
        key: String = "",
        environmentCustomization: @escaping (inout ViewEnvironment) -> Void = { _ in }
    ) {
        self.key = key
        self.environmentCustomization = environmentCustomization
    }

    public func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
        ModalBehaviorPreferences(usesPreferredContentSize: false)
    }

    public func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
        ModalDisplayValues(
            frame: context.containerCoordinateSpace.bounds,
            overlayOpacity: 0.6
        )
    }

    public func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(
            frame: CGRect(
                x: 0,
                y: context.containerSize.height,
                width: context.containerSize.width,
                height: context.containerSize.height
            )
        )
    }

    public func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(
            frame: CGRect(
                x: 0,
                y: context.containerSize.height,
                width: context.containerSize.width,
                height: context.containerSize.height
            )
        )
    }

    public func customize(environment: inout ViewEnvironment) {
        environmentCustomization(&environment)
    }
}
