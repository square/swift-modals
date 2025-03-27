import UIKit

/// Transition values describe how a modal should appear at the start or end of its enter or
/// exit transitions. Unless otherwise specified, the transition from or to these values will be
/// animated.
public struct ModalTransitionValues {
    /// The frame, in the coordinate space of the container specified by the
    /// `ModalPresentationContext`.
    public var frame: CGRect
    /// An alpha value to apply to the modal's view. Defaults to `1`.
    public var alpha: CGFloat
    /// A transform to apply to the modal.
    public var transform: CGAffineTransform
    /// A corner style to apply to the modal during transitions. This value is applied immediately
    /// at the start of transitions and is not animated. Defaults to `.none`, for square corners.
    public var roundedCorners: ModalRoundedCorners
    /// An opacity to apply to the overlay view behind the modal. Defaults to `0`, for a
    /// completely transparent overlay view.
    public var overlayOpacity: CGFloat
    /// An opacity to apply to decorations during transitions
    public var decorationOpacity: CGFloat
    /// The animation to use during the transition. Defaults to `.spring()` which matches the system.
    public var animation: ModalAnimation

    /// Create a new set of transition values.
    public init(
        frame: CGRect,
        alpha: CGFloat = 1,
        transform: CGAffineTransform = .identity,
        overlayOpacity: CGFloat = 0,
        roundedCorners: ModalRoundedCorners = .none,
        decorationOpacity: CGFloat = 0,
        animation: ModalAnimation = .spring()
    ) {
        self.frame = frame
        self.alpha = alpha
        self.transform = transform
        self.overlayOpacity = overlayOpacity
        self.roundedCorners = roundedCorners
        self.decorationOpacity = decorationOpacity
        self.animation = animation
    }
}
