import UIKit


/// Transition values describe how a toast should appear at the start or end of its enter or exit transitions.
///
public struct ToastTransitionValues {

    /// The target frame of the toast for this transition within the container's frame.
    ///
    public var frame: CGRect

    /// The target opacity for this transition.
    ///
    /// Defaults to `1`.
    ///
    public var alpha: CGFloat

    /// The target transform for this transition.
    ///
    /// Defaults to `.identity`.
    ///
    public var transform: CGAffineTransform

    /// The animation to use during the transition. Defaults to `.spring()` which matches the system.
    ///
    /// Defaults to `.spring()`.
    ///
    public var animation: ModalAnimation

    /// The shadow to use for this transition.
    ///
    /// The default value is `.none`.
    ///
    public var shadow: ModalShadow

    /// A corner style to apply to the modal during transitions.
    ///
    /// The default value is `.none`.
    ///
    public var roundedCorners: ModalRoundedCorners

    /// Create a new set of transition values.
    ///
    public init(
        frame: CGRect,
        alpha: CGFloat = 1,
        transform: CGAffineTransform = .identity,
        animation: ModalAnimation = .spring(),
        shadow: ModalShadow = .none,
        roundedCorners: ModalRoundedCorners = .none
    ) {
        self.frame = frame
        self.alpha = alpha
        self.transform = transform
        self.animation = animation
        self.shadow = shadow
        self.roundedCorners = roundedCorners
    }
}
