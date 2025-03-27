import UIKit

/// Modal and toast presentation views both need to pass through touches on themselves (e.g., only subviews should be
/// interactable). They also need to increase their hit target to match the frame of their ancestor presentation
/// view, if one exists.
final class ModalPresentationPassthroughView: UIView {
    private let ancestorView: () -> UIView?

    init(frame: CGRect, ancestorView: @escaping () -> UIView?) {
        self.ancestorView = ancestorView
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        /// If we have an ancestor view, return true if the point is inside that view (which may have a larger frame).
        if let ancestorView = ancestorView() {
            let point = convert(point, to: ancestorView)
            return ancestorView.point(inside: point, with: event)
        } else {
            return super.point(inside: point, with: event)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        /// Only return the result if it's not `self` (e.g., if its one of our subviews).
        let result = super.hitTest(point, with: event)
        return result == self ? nil : result
    }
}
