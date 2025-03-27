/// A description of how the contents of a ``ModalList`` should be filtered for presentation.
public struct ModalPresentationFilter {
    /// A unique identifier for the filter. A change in identifier should trigger a re-evaluation of modal
    /// presentation.
    @_spi(ModalsImplementation)
    public let identifier: AnyHashable

    /// `true` if the modal should be presented locally and `false` if it should be forwarded
    /// to an ancestor.
    let modalPredicate: (PresentableModal) -> Bool

    /// `true` if a toast should be presented locally and `false` if it should be forwarded
    /// to an ancestor.
    let toastPredicate: (PresentableToast) -> Bool

    @_spi(ModalsImplementation)
    public func presentedLocally(_ list: ModalList) -> ModalList {
        ModalList(
            modals: list.modals.filter(modalPredicate),
            toasts: list.toasts.filter(toastPredicate),
            toastSafeAreaAnchors: list.toastSafeAreaAnchors
        )
    }

    @_spi(ModalsImplementation)
    public func presentedByAncestor(_ list: ModalList) -> ModalList {
        ModalList(
            modals: list.modals.filter { !modalPredicate($0) },
            toasts: list.toasts.filter { !toastPredicate($0) },
            toastSafeAreaAnchors: list.toastSafeAreaAnchors
        )
    }

    public static var passThroughToasts: ModalPresentationFilter {
        .init(
            identifier: "pass-through-toasts",
            modalPredicate: { _ in true },
            toastPredicate: { _ in false }
        )
    }

    public static func containsUniqueKey(
        _ key: (some UniqueModalInfoKey).Type
    ) -> ModalPresentationFilter {
        .init(
            identifier: ObjectIdentifier(key),
            modalPredicate: { $0.info.contains(key) },
            toastPredicate: { _ in false }
        )
    }
}
