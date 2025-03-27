import UIKit

/// Use modal decorations to add decorative views to modal presentations.
///
/// Note that you must provide a frame. The frame is defined _relative to the frame of the presented
/// modal_. That is, if you want the decoration to appear at the modal's origin, use `(0, 0)`.
///
/// This frame will be used relative to the enter, display or exit values of your modal,
/// depending on the state of the presentation. This means the decoration will move alongside
/// your modal view.
public struct ModalDecoration {
    /// The frame of the direction, expressed _relative to the frame of the presented modal_.
    public var frame: CGRect
    /// Invoked when creating a new modal decoration view.
    public var build: () -> (UIView)
    /// Invoked when updating an existing modal decoration view.
    public var update: (UIView) -> Void
    /// Whether or not `update` can be invoked on the given view.
    public var canUpdate: (UIView) -> Bool

    /// Create a new modal decoration.
    public init<View: UIView>(
        frame: CGRect,
        build: @escaping () -> View,
        update: @escaping (View) -> Void,
        canUpdate: @escaping (UIView) -> Bool = { $0 is View }
    ) {
        self.frame = frame
        self.build = build
        self.update = { update($0 as! View) }
        self.canUpdate = canUpdate
    }
}
