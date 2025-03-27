import UIKit

/// Options for a shadow to be placed behind a modal.
public struct ModalShadow: Equatable {
    public static let none = ModalShadow(radius: 0, opacity: 0, offset: .zero, color: .black)

    /// The blur radius of the shadow.
    public var radius: CGFloat

    /// The opacity of the shadow.
    public var opacity: CGFloat

    /// The offset of the shadow.
    public var offset: UIOffset

    /// The color of the shadow.
    public var color: UIColor

    /// Create a new shadow
    public init(radius: CGFloat, opacity: CGFloat, offset: UIOffset, color: UIColor) {
        self.radius = radius
        self.opacity = opacity
        self.offset = offset
        self.color = color
    }
}
