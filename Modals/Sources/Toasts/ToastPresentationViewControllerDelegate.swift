import Foundation


/// Allows consumers of ``ToastPresentationViewController`` to respond to updates to its content.
///
public protocol ToastPresentationViewControllerDelegate: AnyObject {

    /// Called when the ``ToastPresentationViewController``'s number of visible toasts transitions from none to some or
    /// visa versa.
    ///
    /// - Note: that this is different from whether or not ``PresentableToast``s are currently provided to the
    ///   ``ToastPresentationViewController``—when a toast is removed form the list of ``PresentableToast``s it still
    ///   needs to perform the transition out animation.
    ///
    func toastPresentationViewControllerDidChange(hasVisiblePresentations: Bool)
}
