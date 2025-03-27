import Modals
import UIKit

/// A basic toast container presentation style.
///
/// - Note: This style primarily handles toast appearance preferences. See
///   ``ExampleToastPresentationStyle`` for behavior preferences
///   (e.g. auto-dismiss, interactive dismissal, etc.).
///
public struct ExampleToastContainerPresentationStyle: Equatable, ToastContainerPresentationStyle {

    /// The spacing between toasts.
    ///
    public var spacing: CGFloat

    /// The ideal width of presented toasts.
    ///
    /// If the available space (minus padding) is less than this target width, the toast may appear smaller than
    /// this target width.
    ///
    public var targetWidth: CGFloat = 600

    /// The padding between the edges of all toasts and the container view.
    ///
    public var padding: UIEdgeInsets

    /// The corner radius to apply to toasts.
    ///
    public var cornerRadius: CGFloat = 6

    public var shadow: ModalShadow

    public init(
        spacing: CGFloat = 16,
        targetWidth: CGFloat = 600,
        padding: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
        cornerRadius: CGFloat = 6,
        shadow: ModalShadow = ModalShadow(
            radius: 9,
            opacity: 0.2,
            offset: UIOffset(horizontal: 0, vertical: 4),
            color: .black
        )
    ) {
        self.spacing = spacing
        self.targetWidth = targetWidth
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }

    private var roundedCorners: ModalRoundedCorners {
        ModalRoundedCorners(
            radius: 6,
            corners: .all,
            curve: .continuous
        )
    }

    public func displayValues(for context: ToastDisplayContext) -> ToastDisplayValues {
        var presentedValues: [ToastTransitionValues] = []
        presentedValues.reserveCapacity(context.preheatValues.count)

        let containerSize = context.containerSize
        let safeAreaInsets = context.safeAreaInsets

        let maxWidth = containerSize.width - safeAreaInsets.horizontal - padding.horizontal
        let width = min(targetWidth, maxWidth)

        var endY = containerSize.height - safeAreaInsets.bottom - padding.bottom
        for preheatValues in context.preheatValues.reversed() {
            presentedValues.append(
                ToastTransitionValues(
                    frame: CGRect(
                        x: (containerSize.width / 2 - width / 2).rounded(),
                        y: endY - preheatValues.preferredContentSize.height,
                        width: width,
                        height: preheatValues.preferredContentSize.height
                    ),
                    shadow: shadow,
                    roundedCorners: roundedCorners
                )
            )

            endY -= spacing + preheatValues.preferredContentSize.height
        }

        return .init(presentedValues: presentedValues.reversed())
    }

    public func enterTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues {
        var frame = context.displayFrame
        frame.origin.y = context.containerSize.height
        return ToastTransitionValues(
            frame: frame,
            shadow: shadow,
            roundedCorners: roundedCorners
        )
    }

    public func exitTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues {
        var frame = context.displayFrame
        frame.origin.y = context.containerSize.height
        return ToastTransitionValues(
            frame: frame,
            shadow: shadow,
            roundedCorners: roundedCorners
        )
    }

    public func interactiveExitTransitionValues(for context: ToastInteractiveExitContext) -> ToastTransitionValues {
        var frame = context.presentedFrame
        frame.origin.y = context.containerSize.height
        return ToastTransitionValues(
            frame: frame,
            animation: .spring(initialVelocity: context.velocity),
            shadow: shadow,
            roundedCorners: roundedCorners
        )
    }

    public func reverseTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues {
        var frame = context.displayFrame
        frame.origin.y -= 20
        return ToastTransitionValues(
            frame: frame,
            animation: .cubicBezier(
                // These control points define an ease-out curve.
                // See visualization at https://cubic-bezier.com/#.33,1,.68,1
                controlPoint1: CGPoint(x: 0.33, y: 1),
                controlPoint2: CGPoint(x: 0.68, y: 1),
                // This animator is only used for scrubbing, so the duration is unused.
                duration: 1
            ),
            shadow: shadow,
            roundedCorners: roundedCorners
        )
    }

    public func preheatValues(for context: ToastPreheatContext) -> ToastPreheatValues {
        let containerSize = context.containerSize
        let safeAreaInsets = context.safeAreaInsets

        let maxWidth = containerSize.width - safeAreaInsets.horizontal - padding.horizontal
        let maxHeight = containerSize.height - safeAreaInsets.vertical - padding.vertical

        return ToastPreheatValues(
            size: CGSize(
                width: min(targetWidth, maxWidth),
                height: maxHeight
            )
        )
    }
}

extension UIEdgeInsets {

    fileprivate var horizontal: CGFloat {
        left + right
    }

    fileprivate var vertical: CGFloat {
        top + bottom
    }
}
