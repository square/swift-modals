import UIKit

/// A corner rounding style that can be applied to presented modals from `ModalDisplayValues` or
/// `ModalTransitionValues`.
public struct ModalRoundedCorners {
    /// Square corners.
    public static let none = ModalRoundedCorners(radius: 0, corners: [], curve: .circular)

    /// The corner radius.
    public var radius: CGFloat
    /// The set of corners to be rounded.
    public var corners: CACornerMask
    /// The shape of the rounding.
    public var curve: Curve

    /// Create a new set of rounded corners.
    /// - Parameters:
    ///   - radius: The corner radius.
    ///   - corners: The set of corners to be rounded. Defaults to all corners.
    ///   - curve: The shape of the curve. Defaults to a continuous curve.
    public init(
        radius: CGFloat,
        corners: CACornerMask = .all,
        curve: Curve = .continuous
    ) {
        self.radius = radius
        self.corners = corners
        self.curve = curve
    }

    /// A wrapper for `CALayerCornerCurve`.
    public enum Curve: Int {
        /// Corresponds to `CALayerCornerCurve.circular`.
        case circular
        /// Corresponds to `CALayerCornerCurve.continuous`.
        case continuous

        var caLayerCornerCurve: CALayerCornerCurve {
            switch self {
            case .circular: .circular
            case .continuous: .continuous
            }
        }
    }

    public func apply(toView view: UIView) {
        view.layer.cornerRadius = radius
        view.layer.maskedCorners = corners
        view.layer.cornerCurve = curve.caLayerCornerCurve
    }
}
