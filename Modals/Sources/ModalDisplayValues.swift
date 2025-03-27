import UIKit

/// Display values describe how a modal should be presented in a specific context. They are used by
/// the modal presentation system to position modal containers, perform transitions, and add
/// additional UI elements, such as shadows and overlay views.
public struct ModalDisplayValues {
    /// The frame, in the coordinate space of the container specified by the
    /// `ModalPresentationContext`.
    public var frame: CGRect
    /// An alpha value to apply to the modal's view. Defaults to `1`.
    public var alpha: CGFloat
    /// The corner style to apply to the modal. Defaults to `.none`, for square corners.
    public var roundedCorners: ModalRoundedCorners
    /// An opacity to apply to the overlay view behind the modal. Defaults to `0`, for a
    /// completely transparent overlay view.
    public var overlayOpacity: CGFloat
    /// The color of the overlay view behind the modal. Defaults to `.black`.
    public var overlayColor: UIColor
    /// A shadow to show behind the modal.
    public var shadow: ModalShadow
    /// Decorations to show alongside the modal.
    public var decorations: [ModalDecoration]

    /// Create a new set of modal display values.
    public init(
        frame: CGRect,
        alpha: CGFloat = 1,
        roundedCorners: ModalRoundedCorners = .none,
        overlayOpacity: CGFloat = 0,
        overlayColor: UIColor = .black,
        shadow: ModalShadow = .none,
        decorations: [ModalDecoration] = []
    ) {
        self.frame = frame
        self.alpha = alpha
        self.roundedCorners = roundedCorners
        self.overlayOpacity = overlayOpacity
        self.overlayColor = overlayColor
        self.shadow = shadow
        self.decorations = decorations
    }
}
