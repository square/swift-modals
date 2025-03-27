import Modals
import UIKit

/// An example of a popover-style modal that is positioned relative to some anchor rectangle.
///
/// This implementation chooses a position depending on the anchor's position relative to the
/// container, and tries to keep the popover away from the edges.
///
public struct PopoverModalStyle: ModalPresentationStyle {

    public var stylesheet: ModalStylesheet

    /// The anchor that determines this modal's positioning.
    public weak var anchor: UICoordinateSpace?

    /// A callback that will be called when this modal should be dismissed due to tapping outside
    /// the modal bounds.
    public var onDismiss: () -> Void

    public init(
        stylesheet: ModalStylesheet,
        anchor: UICoordinateSpace,
        onDismiss: @escaping () -> Void
    ) {
        self.stylesheet = stylesheet
        self.anchor = anchor
        self.onDismiss = onDismiss
    }

    public func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
        ModalBehaviorPreferences(
            overlayTap: .dismiss(onDismiss: onDismiss),
            usesPreferredContentSize: true
        )
    }

    public func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
        ModalDisplayValues(
            frame: position(in: context).frame,
            roundedCorners: roundedCorners,
            overlayOpacity: 1,
            overlayColor: .clear,
            shadow: stylesheet.shadow
        )
    }

    public func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {

        let position = position(in: context)

        // We're okay crashing here since it's a programmer error to use a popover with an unanchored anchor.
        let anchorFrame = try! anchorFrame(in: context)

        let dx: CGFloat
        let dy: CGFloat

        // Offset by half the value scaled down, so that the scale in appears to grow from
        // the anchor frame in the x-axis.
        let offsetX = position.frame.width * (1.0 - stylesheet.enterScale) / 2

        switch position.horizontalSide {
        case .center:
            dx = 0
        case .left:
            dx = -offsetX
        case .right:
            dx = offsetX
        }

        // In the y-axis, if the center of the anchor frame is within the modal frame,
        // we want to grow from the center of the anchor frame.
        // Otherwise, grow from the edge like we do in the x-axis.
        if (position.frame.minY..<position.frame.maxY).contains(anchorFrame.midY) {
            dy = (anchorFrame.center.y - position.frame.center.y) / 2
        } else {
            let offsetY = position.frame.height * (1.0 - stylesheet.enterScale) / 2

            switch position.verticalSide {
            case .top:
                dy = -offsetY
            case .bottom:
                dy = offsetY
            }
        }

        let transform = CGAffineTransform
            .identity
            .scaledBy(x: stylesheet.enterScale, y: stylesheet.enterScale)
            .translatedBy(x: dx, y: dy)

        return ModalTransitionValues(
            frame: position.frame,
            alpha: 0,
            transform: transform,
            roundedCorners: roundedCorners,
            animation: stylesheet.scaleInAnimation
        )
    }

    public func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(
            frame: position(in: context).frame,
            alpha: 0,
            roundedCorners: roundedCorners,
            animation: stylesheet.scaleOutAnimation
        )
    }

    private var roundedCorners: ModalRoundedCorners {
        ModalRoundedCorners(radius: stylesheet.cornerRadius)
    }

    private func position(in context: ModalPresentationContext) -> Position {
        let anchorFrame: CGRect

        // To avoid crashing if the anchor loses its coordinate space before disappearing, we have some fallbacks:
        if let frame = try? self.anchorFrame(in: context) {
            // 1. Use the anchor frame if we have one.
            anchorFrame = frame
        } else if let currentFrame = context.currentFrame.value {
            // 2. Fallback to the current frame of the modal if it exists.
            return Position(
                frame: currentFrame,
                verticalSide: .top,
                horizontalSide: .center
            )
        } else {
            // 3. Finally, if we have no anchor frame or current frame, just use the
            // container frame as an anchor and compute a frame based on that.
            // (this will probably never really happen, but is better than crashing).
            anchorFrame = context.containerCoordinateSpace.bounds
        }

        // The maximum size is a size that fits within our containers safe area
        // and has room for padding on the edges..
        let maxSize = context.containerSize
            .subtracting(insets: context.containerSafeAreaInsets)
            .subtracting(insets:
                UIEdgeInsets(
                    top: stylesheet.verticalAnchorSpacing,
                    left: stylesheet.horizontalAnchorSpacing,
                    bottom: stylesheet.verticalAnchorSpacing,
                    right: stylesheet.horizontalAnchorSpacing
                )
            )
            .upperBounded(byWidth: stylesheet.cardMaximumWidth)

        // The size is at least as wide as the anchor and the  minimum width,
        // and bounded by our maximum size and  maximum height.
        var size = (context.preferredContentSize.value ?? context.containerSize)

        size = size
            .lowerBounded(byWidth: stylesheet.minimumWidth)
            .upperBounded(by: maxSize)
            .upperBounded(byHeight: stylesheet.maximumHeight)

        return position(in: context, anchoredTo: anchorFrame, size: size)
    }

    private func position(
        in context: ModalPresentationContext,
        anchoredTo anchorFrame: CGRect,
        size: CGSize
    ) -> Position {
        let containerSize = context.containerSize
        let containerSafeAreaInsets = context.containerSafeAreaInsets
        let containerMidX = containerSize.width / 2
        let containerMidY = containerSize.height / 2

        let x: CGFloat
        let y: CGFloat
        let verticalSide: VerticalSide
        let horizontalSide: HorizontalSide

        // First, determine x and y values "ideally"
        // without worrying about positioning the modal off-screen.
        if size.width == anchorFrame.width {
            x = anchorFrame.minX
            horizontalSide = .center
        } else if anchorFrame.midX <= containerMidX {
            x = anchorFrame.minX
            horizontalSide = .left
        } else {
            x = anchorFrame.maxX - size.width
            horizontalSide = .right
        }

        if anchorFrame.midY < containerMidY {
            y = anchorFrame.maxY + stylesheet.verticalAnchorSpacing
            verticalSide = .top
        } else {
            y = anchorFrame.minY - stylesheet.verticalAnchorSpacing - size.height
            verticalSide = .bottom
        }

        // Next, adjust our x and y so the modal is on-screen and inset by padding.
        let origin = CGPoint(
            x: x.lowerBounded(by: containerSafeAreaInsets.left + stylesheet.horizontalAnchorSpacing)
                .upperBounded(by: containerSize.width
                    - size.width
                    - containerSafeAreaInsets.right
                    - stylesheet.horizontalAnchorSpacing),
            y: y.lowerBounded(by: containerSafeAreaInsets.top + stylesheet.verticalAnchorSpacing)
                .upperBounded(by: containerSize.height
                    - size.height
                    - containerSafeAreaInsets.bottom
                    - stylesheet.verticalAnchorSpacing)
        )

        // This is our best frame based on the ideal positioning, then moved on-screen.
        var frame = CGRect(origin: origin, size: size)

        // If our best frame fully contains the anchor, and our ideal position is to one side,
        // we check if we have room to move to the side of the anchor frame; if so, we do.
        if frame.contains(anchorFrame) {
            switch horizontalSide {
            case .center:
                break

            case .left:
                if frame.maxX + anchorFrame.width + stylesheet.horizontalAnchorSpacing <
                    containerSize.width - containerSafeAreaInsets.right - stylesheet.horizontalAnchorSpacing
                {
                    frame.origin.x += anchorFrame.width + stylesheet.horizontalAnchorSpacing
                }

            case .right:
                if frame.minX - anchorFrame.width - stylesheet.horizontalAnchorSpacing >
                    containerSafeAreaInsets.left + stylesheet.horizontalAnchorSpacing
                {
                    frame.origin.x -= anchorFrame.width + stylesheet.horizontalAnchorSpacing
                }
            }
        }

        return Position(
            frame: frame,
            verticalSide: verticalSide,
            horizontalSide: horizontalSide
        )
    }

    private func anchorFrame(in context: ModalPresentationContext) throws -> CGRect {
        guard let anchor else {
            throw AnchorError.unresolvedCoordinateSpace
        }

        return anchor.convert(anchor.bounds, to: context.containerCoordinateSpace)
    }
}

extension PopoverModalStyle {
    private struct Position {
        var frame: CGRect
        var verticalSide: VerticalSide
        var horizontalSide: HorizontalSide
    }

    private enum VerticalSide: Equatable {
        case top, bottom
    }

    private enum HorizontalSide: Equatable {
        case left, right, center
    }
}

extension CGRect {
    /// The coordinate at the center of the receiver.
    public var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

enum AnchorError: Error, CustomStringConvertible {
    case unresolvedCoordinateSpace

    var description: String {
        switch self {
        case .unresolvedCoordinateSpace:
            "Popover anchor was not set or went away"
        }
    }
}
