import UIKit


/// A [ModalHost](x-source-tag://ModalHost) that can provide a `ToastPresenter` for presenting
/// toasts scoped to the host's content, rather than to the presenting view controller.
///
/// Toasts presented through `contentToastPresenter` are owned by the host's content, so they are
/// unaffected by the triggering view controller leaving the hierarchy (e.g. a navigation pop):
/// they remain presented until dismissed via their `ModalLifetime`, or until the host's content
/// itself leaves the hierarchy. As with any toast presentation, the returned `ModalLifetime`
/// must be retained — deallocating it dismisses the toast — so retain it with an owner that
/// outlives the triggering view controller.
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
/// if let host = rootModalHost as? HostToastPresenting {
///     let lifetime = host.contentToastPresenter.present(toastViewController)
///     // Retain `lifetime` with an owner that outlives this view controller;
///     // releasing it (or calling `dismiss()`) dismisses the toast.
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
