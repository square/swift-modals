import UIKit

/// A description of how the contents of a ``ModalList`` should be filtered for presentation.
public struct ModalPresentationFilter {

    /// Information about the host that is applying a filter.
    public struct Context {
        /// The view controller of the modal host that is applying the filter.
        ///
        /// A filter can use the host's position in the view controller hierarchy to decide where a modal presents.
        /// If that decision depends on state outside of the modal, call ``ModalHost/setNeedsModalUpdate()`` on the
        /// host when the state changes, so that the host applies the filter again.
        public let host: UIViewController

        @_spi(ModalsImplementation)
        public init(host: UIViewController) {
            self.host = host
        }
    }

    /// A unique identifier for the filter. A change in identifier should trigger a re-evaluation of modal
    /// presentation.
    @_spi(ModalsImplementation)
    public let identifier: AnyHashable

    /// `true` if the modal should be presented locally and `false` if it should be forwarded
    /// to an ancestor.
    let modalPredicate: (PresentableModal, Context) -> Bool

    /// `true` if a toast should be presented locally and `false` if it should be forwarded
    /// to an ancestor.
    let toastPredicate: (PresentableToast, Context) -> Bool

    /// Creates a filter that decides which modals and toasts a host presents locally. The host forwards the rest to
    /// its nearest ancestor host. A host without an ancestor host presents everything locally.
    ///
    /// - Parameters:
    ///   - identifier: A unique identifier for the filter. When a host's filter identifier changes, the host
    ///     re-evaluates where its modals present.
    ///   - presentsModalLocally: Returns `true` if the host should present the modal, or `false` if it should
    ///     forward the modal to its ancestor host.
    ///   - presentsToastLocally: Returns `true` if the host should present the toast, or `false` if it should
    ///     forward the toast to its ancestor host.
    public init(
        identifier: AnyHashable,
        presentsModalLocally: @escaping (PresentableModal, Context) -> Bool,
        presentsToastLocally: @escaping (PresentableToast, Context) -> Bool
    ) {
        self.identifier = identifier
        modalPredicate = presentsModalLocally
        toastPredicate = presentsToastLocally
    }

    @_spi(ModalsImplementation)
    public func presentedLocally(_ list: ModalList, in context: Context) -> ModalList {
        ModalList(
            modals: list.modals.filter { modalPredicate($0, context) },
            toasts: list.toasts.filter { toastPredicate($0, context) },
            toastSafeAreaAnchors: list.toastSafeAreaAnchors
        )
    }

    @_spi(ModalsImplementation)
    public func presentedByAncestor(_ list: ModalList, in context: Context) -> ModalList {
        ModalList(
            modals: list.modals.filter { !modalPredicate($0, context) },
            toasts: list.toasts.filter { !toastPredicate($0, context) },
            toastSafeAreaAnchors: list.toastSafeAreaAnchors
        )
    }

    public static var passThroughToasts: ModalPresentationFilter {
        .init(
            identifier: "pass-through-toasts",
            presentsModalLocally: { _, _ in true },
            presentsToastLocally: { _, _ in false }
        )
    }

    public static func containsUniqueKey(
        _ key: (some UniqueModalInfoKey).Type
    ) -> ModalPresentationFilter {
        .init(
            identifier: ObjectIdentifier(key),
            presentsModalLocally: { modal, _ in modal.info.contains(key) },
            presentsToastLocally: { _, _ in false }
        )
    }
}
