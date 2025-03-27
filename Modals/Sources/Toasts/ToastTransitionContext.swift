import UIKit

/// Contextual information provided to `ToastContainerPresentationStyle` when getting transition values for an
/// individual toast.
///
public struct ToastTransitionContext {

    /// The frame of the toast in the container in the "presented" state.
    ///
    public var displayFrame: CGRect

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

    /// Creates a new transition context.
    ///
    public init(
        displayFrame: CGRect,
        containerSize: CGSize,
        safeAreaInsets: UIEdgeInsets,
        scale: CGFloat
    ) {
        self.displayFrame = displayFrame
        self.containerSize = containerSize
        self.safeAreaInsets = safeAreaInsets
        self.scale = scale
    }
}
