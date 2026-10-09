import UIKit

/// Contains a view controller and all the information needed to present it modally.
///
/// PresentableModal instances are attached to view controllers and aggregated up the view controller hierarchy
/// using the `UIViewController.aggregateModals` extension.
///
/// Generally, you should not need to create `PresentableModal` instances yourself. Instead, use one of the
/// following methods to present modals:
///
/// From a vanilla view controller, use `UIViewController.presenter` to get a `ModalPresenter`, and
/// call `ModalPresenter.present(_:,style:,completion:)`.
///
/// From a workflow, render a `ModalContainer` screen containing your screen and the screens
/// of any modals you want to present above it.
///
/// ## See Also:
/// - [ModalPresenter.present(_:,style:,completion:)](x-source-tag://ModalPresenter.present)
/// - [ModalContainer](x-source-tag://ModalContainer)
///
public final class PresentableModal {
    /// The view controller to be presented modally.
    public let viewController: UIViewController

    /// Describes the appearance and behavior of the modal presentation, including:
    /// - the container size and position
    /// - chrome UI, such as shadows and the overlay view
    /// - transitions
    ///
    public let presentationStyle: ModalPresentationStyle

    /// Additional information associated with the modal presentation.
    public let info: ModalInfo

    /// A closure that will be called after the modal has been presented.
    public let onDidPresent: (() -> Void)?

    /// Called at most once after a presenter removes this presentation's container and decorations
    /// and updates its bookkeeping, regardless of appearance state. The latest callback supplied
    /// for the same view controller before removal is used, including nil.
    ///
    /// This reports one presenter's physical removal, not whether the content is still requested.
    /// Forwarding can leave the content in another host. Requesting the same controller during its
    /// exit does not cancel that removal; a subsequent update can create a new presentation.
    ///
    /// Merely hiding a window does not trigger this callback, but removal while hidden does.
    /// Presenter destruction does not guarantee delivery. A modal withdrawn before a presenter
    /// receives it has no presentation to remove and produces no callback.
    public let onDidRemove: (() -> Void)?

    /// Create a new modal.
    public init(
        viewController: UIViewController,
        presentationStyle: ModalPresentationStyle,
        info: ModalInfo,
        onDidRemove: (() -> Void)? = nil,
        // Keep this last and non-defaulted so existing trailing closures still observe presentation.
        onDidPresent: (() -> Void)?
    ) {
        self.viewController = viewController
        self.presentationStyle = presentationStyle
        self.info = info
        self.onDidRemove = onDidRemove
        self.onDidPresent = onDidPresent
    }
}
