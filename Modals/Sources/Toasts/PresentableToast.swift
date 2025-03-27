import Foundation
import UIKit

/// Contains a view controller and all the information needed to present it.
///
/// PresentableToast instances are attached to view controllers and aggregated up the view controller hierarchy using
/// the `UIViewController.aggregateModals` extension.
///
/// Generally, you should not need to create `PresentableToast` instances yourself. Instead, use one of the following
/// methods to present toasts:
///
/// From a vanilla view controller, use `UIViewController.toastPresenter` to get a `ModalPresenter`, and  call
/// `ToastPresenter.present(_:,style:,accessibilityAnnouncement:)`.
///
/// From a workflow, render a `ToastContainer` screen containing your screen and the screens of any toasts you want to
/// present above it.
///
/// ## See Also:
/// - [ToastPresenter.present(_:,style:,accessibilityAnnouncement:)](x-source-tag://ToastPresenter.present)
/// - [ToastContainer](x-source-tag://ToastContainer)
///
public final class PresentableToast {

    /// The view controller to be presented.
    public let viewController: UIViewController

    /// Describes the behavior of the toast presentation (e.g. auto-dismiss, interactive dismissal, etc.).
    ///
    public let presentationStyle: ToastPresentationStyle

    /// The text to read using VoiceOver when the toast is displayed.
    ///
    public let accessibilityAnnouncement: String

    /// Creates a new toast.
    public init(
        viewController: UIViewController,
        presentationStyle: ToastPresentationStyle,
        accessibilityAnnouncement: String
    ) {
        self.viewController = viewController
        self.presentationStyle = presentationStyle
        self.accessibilityAnnouncement = accessibilityAnnouncement
    }
}
