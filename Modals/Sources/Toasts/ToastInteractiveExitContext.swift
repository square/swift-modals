import UIKit

/// The contextual information provided to a `ToastContainerPresentationStyle` when getting interactive exit transition
/// values.
///
public struct ToastInteractiveExitContext {

    /// The frame of the toast when it is in the "presented" state.
    ///
    public var presentedFrame: CGRect

    /// The size of the presentation container.
    ///
    public var containerSize: CGSize

    /// The safe area insets of the container.
    ///
    /// - Note: This accounts for the keyboard frame when appropriate.
    ///
    public var safeAreaInsets: UIEdgeInsets

    /// The natural scale factor associated with the screen the toasts are presented in.
    ///
    public var scale: CGFloat

    /// The velocity vector of the recognized dismiss gesture.
    ///
    public var velocity: CGVector

    /// Creates a new interactive exit context.
    ///
    public init(
        presentedFrame: CGRect,
        containerSize: CGSize,
        safeAreaInsets: UIEdgeInsets,
        scale: CGFloat,
        velocity: CGVector
    ) {
        self.presentedFrame = presentedFrame
        self.containerSize = containerSize
        self.safeAreaInsets = safeAreaInsets
        self.scale = scale
        self.velocity = velocity
    }

    /// A transition context derived from the interactive exit context, useful for calculating
    /// interactive values based on static exit values.
    public var transitionContext: ToastTransitionContext {
        .init(
            displayFrame: presentedFrame,
            containerSize: containerSize,
            safeAreaInsets: safeAreaInsets,
            scale: scale
        )
    }
}
