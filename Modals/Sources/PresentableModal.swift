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

    /// Called at most once after this presentation's container and decorations have been removed from a
    /// presenter and its presentation bookkeeping has been updated, regardless of appearance state.
    /// The latest callback supplied for the same view controller is used, including nil.
    ///
    /// This is local to each presenter: forwarding to a different host may remove a presentation
    /// from the former host while the content remains presented elsewhere. Hiding a window or
    /// destroying a presenter does not deliver this callback. A modal withdrawn before a presenter
    /// accepts it has no presentation to remove and does not deliver it either.
    public let onDidRemove: (() -> Void)?

    /// Create a new modal.
    public init(
        viewController: UIViewController,
        presentationStyle: ModalPresentationStyle,
        info: ModalInfo,
        onDidRemove: (() -> Void)? = nil,
        onDidPresent: (() -> Void)?
    ) {
        self.viewController = viewController
        self.presentationStyle = presentationStyle
        self.info = info
        self.onDidRemove = onDidRemove
        self.onDidPresent = onDidPresent
    }
}
