import UIKit
import ViewEnvironment


extension UIViewController {

    /// Informs the view controller hierarchy that the `preferredContentSize` should
    /// be calculated, as it is required for its display / presentation.
    ///
    /// Defaults to `false`.
    ///
    /// ### When To Set This Value
    /// Set this value to `true` if your view controller or any of its
    /// children should calculate their `preferredContentSize` for proper display within
    /// a self-sizing modal, or other presentation context that requires self-sizing view controllers.
    ///
    /// ### When To Read This Value
    /// When `true`, view controllers which can calculate
    /// `preferredContentSize` should do so, in order to provide proper sizing to
    /// their containing modal or layout. The getter traverses the the parent view controller hierarchy
    /// to determine if any parent view controllers have requested a content size.
    ///
    /// ### Note
    /// You usually do not need to set this value yourself; it will be set by the `Modals` framework
    /// automatically. You only need to set this value yourself if you are managing your own presentation.
    ///
    public var presentationContextWantsPreferredContentSize: Bool {

        set {
            objc_setAssociatedObject(self, &Self.key, newValue, .OBJC_ASSOCIATION_RETAIN)
        }

        get {
            for vc in sequence(first: self, next: \.parent) {
                let wantsSize = objc_getAssociatedObject(vc, &Self.key) as? Bool ?? false

                if wantsSize {
                    return true
                }
            }

            return false
        }
    }

    private static var key: UInt8 = 0
}
