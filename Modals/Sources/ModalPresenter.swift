import UIKit

/// A modal presenter provides methods to present a modal in an imperative fashion, similar to
/// vanilla UIKit modal presentation.
public protocol ModalPresenter {
    /// Presents a modal, by adding it to the list of modals on the view controller that owns this
    /// presenter.
    ///
    /// This function returns a token that must be retained. To dismiss the modal, call the
    /// `dismiss` method on the token. If the token is deallocated, `dismiss` will be called
    /// automatically.
    ///
    /// Do not present a view controller that is already being presented in a modal.
    ///
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to present modally.
    ///   - style: The style describes the appearance and behavior of the modal (such as a full
    ///     screen modal, or a dialog).
    ///   - info: Additional info associated with this modal presentation.
    ///   - completion: A closure that will be called when this modal has been presented.
    /// - Returns: A token that must be kept to dismiss the modal.
    ///
    /// - Tag: ModalPresenter.present
    func present(
        _ viewControllerToPresent: UIViewController,
        style: ModalPresentationStyleProvider,
        info: ModalInfo,
        completion: (() -> Void)?
    ) -> ModalLifetime
}

/// An opaque token used to dismiss a modal that was presented by a `ModalPresenter`.
///
/// If this token is deallocated, the modal will be dismissed automatically.
@objc(MDLModalLifetime) public protocol ModalLifetime: AnyObject {
    /// Dismisses the modal associated with this token.
    @objc func dismiss()
}


// MARK: - Convenience extensions

extension ModalPresenter {

    /// Presents a modal, by adding it to the list of modals on the view controller that owns this
    /// presenter.
    ///
    /// This is a convenience method that has no modal info. See
    /// `present(_:style:completion:)` for more information.
    ///
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to present modally.
    ///   - style: The style describes the appearance and behavior of the modal (such as a full
    ///     screen modal, or a dialog).
    ///   - completion: A closure that will be called when this modal has been presented.
    /// - Returns: A token that must be kept to dismiss the modal.
    ///
    /// ## See Also
    /// [present(_:style:completion:)](x-source-tag://ModalPresenter.present)
    public func present(
        _ viewControllerToPresent: UIViewController,
        style: ModalPresentationStyleProvider,
        completion: (() -> Void)?
    ) -> ModalLifetime {
        present(
            viewControllerToPresent,
            style: style,
            info: .empty(),
            completion: completion
        )
    }

    /// Presents a modal, by adding it to the list of modals on the view controller that owns this
    /// presenter.
    ///
    /// This is a convenience method that has no completion closure. See
    /// `present(_:style:completion:)` for more information.
    ///
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to present modally.
    ///   - style: The style describes the appearance and behavior of the modal (such as a full
    ///     screen modal, or a dialog).
    /// - Returns: A token that must be kept to dismiss the modal.
    ///
    /// ## See Also
    /// [present(_:style:completion:)](x-source-tag://ModalPresenter.present)
    public func present(
        _ viewControllerToPresent: UIViewController,
        style: ModalPresentationStyleProvider
    ) -> ModalLifetime {
        present(
            viewControllerToPresent,
            style: style,
            info: .empty(),
            completion: nil
        )
    }

    /// Presents a modal, by adding it to the list of modals on the view controller that owns this
    /// presenter.
    ///
    /// This is a convenience method for presenting a view controller that conforms to
    /// `ModalPresentable`, and uses the style the view controller provides.
    ///
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to present modally.
    ///   - completion: A closure that will be called when this modal has been presented.
    /// - Returns: A token that must be kept to dismiss the modal.
    ///
    /// ## See Also
    /// [present(_:style:completion:)](x-source-tag://ModalPresenter.present)
    public func present(
        _ viewControllerToPresent: some UIViewController & ModalPresentable,
        completion: (() -> Void)? = nil
    ) -> ModalLifetime {
        present(
            viewControllerToPresent,
            style: viewControllerToPresent.presentationStyle,
            info: viewControllerToPresent.info,
            completion: completion
        )
    }
}
