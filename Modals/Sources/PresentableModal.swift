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

    /// Create a new modal.
    public init(
        viewController: UIViewController,
        presentationStyle: ModalPresentationStyle,
        info: ModalInfo,
        onDidPresent: (() -> Void)?
    ) {
        self.viewController = viewController
        self.presentationStyle = presentationStyle
        self.info = info
        self.onDidPresent = onDidPresent
    }
}
