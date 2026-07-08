import UIKit


/// A [ModalHost](x-source-tag://ModalHost) that can provide a `ToastPresenter` for presenting
/// toasts scoped to the host's content, rather than to the presenting view controller.
///
/// Toasts presented through `contentToastPresenter` are stored by the host's content, so removing
/// the triggering view controller from the hierarchy (e.g. with a navigation pop) does not dismiss
/// them. As with any toast presentation, the returned `ModalLifetime` must be retained —
/// deallocating it dismisses the toast — so retain it with an owner that outlives the triggering
/// view controller.
///
/// Storage and visibility have separate lifetimes: retaining the `ModalLifetime` keeps the toast
/// stored by the content presenter, while the toast is visible only when the host is attached to
/// an active modal-host hierarchy. Detaching a nested host removes its forwarded toast from the
/// former ancestor without dismissing the retained lifetime.
///
/// Presented toasts participate in the host's presentation filter like any other toast within
/// its content: with the default pass-through-toasts filter, a nested host forwards them to its
/// ancestor, so they are displayed by the outermost host.
///
/// To scope a toast's lifetime to a particular view controller instead, use that view
/// controller's `toastPresenter`.
///
/// You can reach a host from any descendent view controller via `modalHost` or `rootModalHost`:
///
/// ```swift
/// final class ToastCoordinator {
///     private var toastLifetime: ModalLifetime?
///
///     func present(
///         _ toastViewController: some UIViewController & ToastPresentable,
///         from trigger: UIViewController
///     ) {
///         guard let host = trigger.rootModalHost as? HostToastPresenting else { return }
///
///         toastLifetime = host.contentToastPresenter.present(toastViewController)
///     }
///
///     func dismissToast() {
///         toastLifetime?.dismiss()
///         toastLifetime = nil
///     }
/// }
/// ```
///
/// - Tag: HostToastPresenting
///
public protocol HostToastPresenting: ModalHost {

    /// A `ToastPresenter` that presents toasts from the root of the host's content, decoupling
    /// their lifetime from any particular descendent view controller.
    var contentToastPresenter: ToastPresenter { get }
}
