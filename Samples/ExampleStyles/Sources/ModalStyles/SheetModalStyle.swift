import Modals
import UIKit

public struct SheetModalStyle: ModalPresentationStyle {

    public var stylesheet: ModalStylesheet
    public var onDismiss: () -> Void

    public init(
        stylesheet: ModalStylesheet,
        onDismiss: @escaping () -> Void
    ) {
        self.stylesheet = stylesheet
        self.onDismiss = onDismiss
    }

    public func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
        ModalBehaviorPreferences(
            overlayTap: .dismiss(onDismiss: onDismiss),
            interactiveDismiss: .swipeDown(onDismiss: onDismiss),
            usesPreferredContentSize: true
        )
    }

    public func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
        let frame = frame(for: context)

        return ModalDisplayValues(
            frame: frame,
            roundedCorners: roundedCorners(),
            overlayOpacity: stylesheet.overlayOpacity,
            decorations: [
                .handle(
                    in: frame,
                    color: stylesheet.handleColor,
                    size: stylesheet.handleSize,
                    offset: stylesheet.handleOffset
                ),
            ]
        )
    }

    public func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(
            frame: enterExitFrame(for: context),
            roundedCorners: roundedCorners()
        )
    }

    public func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(
            frame: enterExitFrame(for: context),
            roundedCorners: roundedCorners()
        )
    }

    public func reverseTransitionValues(for context: ModalPresentationContext) -> ModalReverseTransitionValues? {
        // Move the whole frame up for the reverse transition, since our content isn't stretchy.
        var frame = frame(for: context)
        frame.origin.y -= stylesheet.reverseTransitionInset
        return ModalReverseTransitionValues(frame: frame)
    }

    private func enterExitFrame(for context: ModalPresentationContext) -> CGRect {
        var frame = frame(for: context)
        frame.origin.y = context.containerSize.height
        return frame
    }

    private func roundedCorners() -> ModalRoundedCorners {
        ModalRoundedCorners(radius: stylesheet.cornerRadius, corners: .all, curve: .continuous)
    }

    private func frame(for context: ModalPresentationContext) -> CGRect {
        // Sheet modal is inset by the safe area insets
        let availableSize = context.containerSize
            .subtracting(insets: context.containerSafeAreaInsets)
            .subtracting(width: stylesheet.horizontalInsets)
            .subtracting(height: stylesheet.verticalInsets)

        let maximumHeight = availableSize.height

        // This style should only be used if the viewport is > maximumWidth,
        // but ensure we don't overflow just in case.
        let modalWidth = availableSize.width.upperBounded(by: stylesheet.cardMaximumWidth)

        let modalHeight = context.preferredContentSize.value?.height
            .upperBounded(by: maximumHeight) ?? maximumHeight

        // Center in the x-axis, and position relative to the safe area in the y-axis.
        let origin = CGPoint(
            x: (context.containerSize.width - modalWidth) / 2,
            y: context.containerSize.height
                - context.containerSafeAreaInsets.bottom
                - stylesheet.verticalInsets
                - modalHeight
        )

        let size = CGSize(width: modalWidth, height: modalHeight)
        return CGRect(origin: origin, size: size)
    }
}
