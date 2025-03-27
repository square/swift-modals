import UIKit


/// A toast presenter provides methods to present a toast in an imperative fashion, similar to vanilla UIKit modal
/// presentation.
///
public protocol ToastPresenter {

    /// Presents a toast, by adding it to the list of toasts on the view controller that owns this presenter.
    ///
    /// This function returns a token that must be retained. To dismiss the toast, call the `dismiss` method on the
    /// token. If the token is deallocated, `dismiss` will be called automatically.
    ///
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to present.
    ///   - style: The style describes the appearance and behavior of the toast (such as auto-dismiss behaviors).
    ///   - accessibilityAnnouncement: The text to announce using VoiceOver when the toast is presented.
    /// - Returns: A token that must be kept to dismiss the toast.
    ///
    /// - Tag: ToastPresenter.present
    ///
    func present(
        _ viewControllerToPresent: UIViewController,
        style: ToastPresentationStyleProvider,
        accessibilityAnnouncement: String
    ) -> ModalLifetime
}


extension ToastPresenter {

    /// Presents a toast, by adding it to the list of modals on the view controller that owns this presenter.
    ///
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to present.
    /// - Returns: A token that must be kept to dismiss the toast.
    ///
    /// ## See Also
    /// [present(_:style:accessibilityAnnouncement:)](x-source-tag://ToastPresenter.present)
    ///
    public func present(
        _ viewControllerToPresent: some UIViewController & ToastPresentable
    ) -> ModalLifetime {
        present(
            viewControllerToPresent,
            style: viewControllerToPresent.presentationStyle,
            accessibilityAnnouncement: viewControllerToPresent.accessibilityAnnouncement
        )
    }
}
