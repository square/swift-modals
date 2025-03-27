import Modals
import UIKit

public struct FullModalStyle: ModalPresentationStyle {

    public var stylesheet: ModalStylesheet

    public init(stylesheet: ModalStylesheet) {
        self.stylesheet = stylesheet
    }

    public func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
        ModalBehaviorPreferences(usesPreferredContentSize: false)
    }

    public func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
        ModalDisplayValues(
            frame: context.containerCoordinateSpace.bounds,
            overlayOpacity: stylesheet.overlayOpacity
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
        enterTransitionValues(for: context)
    }
}
