import Foundation

/// An Objective-C friendly wrapper for an array of modals.
@objc(MDLModalList)
public final class ModalList: NSObject {
    /// The modal array.
    public let modals: [PresentableModal]

    /// The toast array.
    public let toasts: [PresentableToast]

    /// The toast safe area anchors array.
    public let toastSafeAreaAnchors: [ToastSafeAreaAnchor]

    /// Create a modal list.
    public init(
        modals: [PresentableModal] = [],
        toasts: [PresentableToast] = [],
        toastSafeAreaAnchors: [ToastSafeAreaAnchor] = []
    ) {
        self.modals = modals
        self.toasts = toasts
        self.toastSafeAreaAnchors = toastSafeAreaAnchors
    }

    /// Adds two modal lists together, appending the right hand side modals to the left hand side.
    public static func + (lhs: ModalList, rhs: ModalList) -> ModalList {
        ModalList(
            modals: lhs.modals + rhs.modals,
            toasts: lhs.toasts + rhs.toasts,
            toastSafeAreaAnchors: lhs.toastSafeAreaAnchors + rhs.toastSafeAreaAnchors
        )
    }

    /// Returns a `ModalList` created by appending a collection of modals, toasts, and toast safe area anchors.
    public func appending(
        modals: [PresentableModal] = [],
        toasts: [PresentableToast] = [],
        toastSafeAreaAnchors: [ToastSafeAreaAnchor] = []
    ) -> ModalList {
        self + ModalList(
            modals: modals,
            toasts: toasts,
            toastSafeAreaAnchors: toastSafeAreaAnchors
        )
    }
}
