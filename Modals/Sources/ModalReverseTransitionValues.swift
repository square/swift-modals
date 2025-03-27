import UIKit

/// Reverse transition values describe how a modal should lay out during an interactive dismiss
/// that is panned in the opposite direction of the outgoing direction. The reverse values will
/// be scrubbed to by the interaction with an expontential decay for a spring effect.
public struct ModalReverseTransitionValues {
    /// The frame, in the coordinate space of the container specified by the
    /// `ModalPresentationContext`. Generally this should be offset by ~80pts in the opposite
    /// direction of your dismissal, or offset and with the size increased for stretchy behavior.
    public var frame: CGRect

    /// A transform to scrub to when interacting in the reverse direction of the dismiss.
    public var transform: CGAffineTransform

    /// Create a new set of modal display values.
    public init(
        frame: CGRect,
        transform: CGAffineTransform = .identity
    ) {
        self.frame = frame
        self.transform = transform
    }
}
