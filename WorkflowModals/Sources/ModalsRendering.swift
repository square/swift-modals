import Modals


/// A `Workflow` rendering that contains a list of modals and toasts.
///
/// You do not need to use this rendering type with modals, except in conjunction with the
/// `UIViewController.modalListObserver` bridging facility.
///
/// See ``ModalListObserver`` for more information.
///
public struct ModalsRendering<ModalContent, ToastContent> {

    /// The list of modals.
    ///
    public var modals: [Modal<ModalContent>]

    /// The list of toasts.
    ///
    public var toasts: [Toast<ToastContent>]

    /// Initializes a new `ModalsRendering`.
    ///
    /// - Parameters:
    ///   - modals: The list of modals.
    ///   - toasts: The list of toasts.
    ///
    public init(
        modals: [Modal<ModalContent>],
        toasts: [Toast<ToastContent>]
    ) {
        self.modals = modals
        self.toasts = toasts
    }
}
