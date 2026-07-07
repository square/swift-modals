import UIKit


/// A [ModalHost](x-source-tag://ModalHost) that can provide a `ToastPresenter` for presenting
/// toasts scoped to the host, rather than to the presenting view controller.
///
/// Toasts presented through `contentToastPresenter` are owned by the host's content, so their
/// lifetime is decoupled from the view controller that triggered them: they remain presented
/// across navigation — including removal of the triggering view controller from the hierarchy —
/// until dismissed via their `ModalLifetime`, or until the host's content itself leaves the
/// hierarchy. Use this for fire-and-forget notification toasts, such as a toast presented while
/// the screen that triggered it is being popped.
///
/// To scope a toast's lifetime to a particular view controller instead, use that view
/// controller's `toastPresenter`.
///
/// You can reach a host from any descendent view controller via `modalHost` or `rootModalHost`:
///
/// ```swift
/// if let host = rootModalHost as? HostToastPresenting {
///     self.toastLifetime = host.contentToastPresenter.present(toastViewController)
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
