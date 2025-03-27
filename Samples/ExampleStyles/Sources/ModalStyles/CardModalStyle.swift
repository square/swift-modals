import Modals
import UIKit

public struct CardModalStyle: ModalPresentationStyle {

    public var stylesheet: ModalStylesheet

    /// The sizing behavior for the height of the modal.
    public var sizing: ModalHeightSizing


    public init(
        stylesheet: ModalStylesheet,
        sizing: ModalHeightSizing = .content
    ) {
        self.stylesheet = stylesheet
        self.sizing = sizing
    }

    public func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
        ModalBehaviorPreferences(usesPreferredContentSize: sizing.usesPreferredContentSize)
    }

    public func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
        ModalDisplayValues(
            frame: frame(for: context),
            roundedCorners: roundedCorners(),
            overlayOpacity: stylesheet.overlayOpacity
        )
    }

    public func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(
            frame: frame(for: context),
            alpha: 0,
            transform: CGAffineTransform(scaleX: stylesheet.enterScale, y: stylesheet.enterScale),
            roundedCorners: roundedCorners(),
            animation: stylesheet.scaleInAnimation
        )
    }

    public func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(
            frame: frame(for: context),
            alpha: 0,
            transform: CGAffineTransform(scaleX: stylesheet.exitScale, y: stylesheet.exitScale),
            roundedCorners: roundedCorners(),
            animation: stylesheet.scaleOutAnimation
        )
    }

    private func roundedCorners() -> ModalRoundedCorners {
        ModalRoundedCorners(radius: stylesheet.cornerRadius, corners: .all, curve: .continuous)
    }

    private func frame(for context: ModalPresentationContext) -> CGRect {
        // inset by the safe area insets
        let availableSize = context.containerSize
            .subtracting(insets: context.containerSafeAreaInsets)

        // Ensure our width is narrow enough for our insets;
        // stretch to the maximum width if there's enough room.
        let modalWidth = min(
            stylesheet.cardMaximumWidth,
            availableSize.width - stylesheet.horizontalInsets * 2
        )

        let maximumHeight = availableSize.height - stylesheet.verticalInsets * 2
        let modalHeight = sizing.height(for: context.preferredContentSize, maximumHeight: maximumHeight)

        // Center position.
        let origin = CGPoint(
            x: (context.containerSize.width - modalWidth) / 2,
            y: (context.containerSize.height - modalHeight) / 2
        )

        let size = CGSize(width: modalWidth, height: modalHeight)
        return CGRect(origin: origin, size: size)
    }
}
