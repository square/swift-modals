import Foundation
import UIKit

@available(iOSApplicationExtension, unavailable, message: "This depends on the UIApplication singleton")
extension UIResponder {

    /// Calling `findFirstResponder` stores `self` into this property so that `currentFirstResponder` can return it.
    private weak static var _discoveredCurrentFirstResponder: UIResponder?

    @objc
    private func mdl_findFirstResponder() {
        Self._discoveredCurrentFirstResponder = self
    }

    /// Get the current first responder.
    static var currentFirstResponder: UIResponder? {
        // Ensure the last discovered first responder isn't returned.
        _discoveredCurrentFirstResponder = nil
        // Send `findFirstResponder` to `nil` (which sends it to the first responder) so that the first responder
        // stores itself in `_discoveredCurrentFirstResponder`.
        UIApplication.shared.sendAction(#selector(mdl_findFirstResponder), to: nil, from: nil, for: nil)
        return _discoveredCurrentFirstResponder
    }

    /// Resigns the current first responder by sending a `resignFirstResponder` action to `nil`.
    /// (This behavior is documented in the API docs for `sendAction`).
    static func resignCurrentFirstResponder() {
        UIApplication.shared.sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension UIResponder {

    func isDescendant(of otherResponder: UIResponder) -> Bool {
        var nextResponder: UIResponder? = self

        while nextResponder != nil {
            if nextResponder === otherResponder {
                return true
            } else {
                nextResponder = nextResponder?.next
            }
        }

        return false
    }
}
