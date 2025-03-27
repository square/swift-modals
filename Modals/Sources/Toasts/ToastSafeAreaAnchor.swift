import UIKit


// The Obj-C Associated Object API requires this to be mutable.
private var storedToastSafeAreaAnchorKey: UInt8 = 0


extension UIViewController {

    /// Defines the safe area for toasts presented with the `Modals` framework.
    ///
    /// - Note: These anchors are only respected as long as no modals are present.
    ///
    public var toastSafeAreaAnchor: ToastSafeAreaAnchor {
        let anchor: ToastSafeAreaAnchor
        if let existingAnchor = storedToastSafeAreaAnchor {
            anchor = existingAnchor
        } else {
            anchor = ToastSafeAreaAnchor(onChange: { [weak self] in
                self?.modalHost?.setNeedsModalUpdate()
            })
            objc_setAssociatedObject(self, &storedToastSafeAreaAnchorKey, anchor, .OBJC_ASSOCIATION_RETAIN)
        }

        if let view = viewIfLoaded {
            anchor.coordinateSpace = view
        }

        return anchor
    }

    /// If `toastSafeAreaAnchor` was previously accessed, `toastSafeAreaAnchor`. Otherwise,`nil`.`
    var storedToastSafeAreaAnchor: ToastSafeAreaAnchor? {
        objc_getAssociatedObject(
            self,
            &storedToastSafeAreaAnchorKey
        ) as? ToastSafeAreaAnchor
    }
}


/// Defines the safe area for toasts presented with the `Modals` framework.
///
/// - Note: These anchors are only respected as long as no modals are present.
///
public class ToastSafeAreaAnchor {

    /// Defines the edge insets which should indicate the edges that should influence the presented toasts safe area
    /// insets as well as the amount to be inset relative to the ``coordinateSpace``.
    ///
    /// A `nil` value for any edge indicates that it will not influence the safe are region for toasts.
    ///
    public struct EdgeInsets: Equatable {

        /// The amount to inset the safe area from the top iff non-nil.
        ///
        public var top: CGFloat?

        /// The amount to inset the safe area from the left iff non-nil.
        ///
        public var left: CGFloat?

        /// The amount to inset the safe area from the bottom iff non-nil.
        ///
        public var bottom: CGFloat?

        /// The amount to inset the safe area from the right iff non-nil.
        ///
        public var right: CGFloat?

        /// The amount to inset the safe area for any edges that are provided with non-nil values.
        ///
        public init(
            top: CGFloat? = nil,
            left: CGFloat? = nil,
            bottom: CGFloat? = nil,
            right: CGFloat? = nil
        ) {
            self.top = top
            self.left = left
            self.bottom = bottom
            self.right = right
        }

        var hasLimits: Bool {
            self != .init()
        }
    }

    /// Defines the edge insets which should indicate the edges that should influence the presented toasts safe area
    /// insets as well as the amount to be inset relative to the ``coordinateSpace``.
    ///
    /// A `nil` value for any edge indicates that it will not influence the safe are region for toasts.
    ///
    public var edgeInsets: EdgeInsets = .init() {
        didSet {
            guard edgeInsets != oldValue else { return }

            onChange()
        }
    }

    /// The coordinate space that this anchor is associated with.
    ///
    /// The values of ``edgeInsets-swift.property`` will be relative to this coordinate space.
    ///
    weak var coordinateSpace: UICoordinateSpace? {
        didSet {
            guard coordinateSpace !== oldValue else { return }

            onChange()
        }
    }

    var onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }
}
