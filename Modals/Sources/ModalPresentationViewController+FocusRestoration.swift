import UIKit

extension ModalPresentationViewController {

    /// An object that manages the storage of focus restoration objects for view controllers and allows
    /// for the retrieval of focus restoration objects for a given view controller.
    struct FocusRestorationStorage {
        private var restorations = NSMapTable<UIViewController, FocusRestoration>.weakToStrongObjects()

        /// Returns the focus restoration for the given view controller.
        ///
        /// If a focus restoration does not already exist for the view controller, one will be created.
        func focusRestoration(for viewController: UIViewController) -> FocusRestoration {
            if let focusRestoration = restorations.object(forKey: viewController) {
                return focusRestoration
            } else {
                let focusRestoration = FocusRestoration(viewController: viewController)
                restorations.setObject(focusRestoration, forKey: viewController)
                return focusRestoration
            }
        }
    }

    /// Allows the first responder managed by a given view controller to be recorded and restored at a later time.
    final class FocusRestoration {

        weak var viewController: UIViewController?

        private(set) weak var firstResponder: UIView?
        weak var focusedAccessibilityElement: NSObject?

        var hasRecordedFirstResponder: Bool {
            firstResponder != nil
        }

        init(viewController: UIViewController) {
            self.viewController = viewController
        }

        func restoreFirstResponder() {
            if let firstResponder, firstResponder.isValidResponder {
                firstResponder.becomeFirstResponder()
            }

            firstResponder = nil
        }

        func clearRecordedResponders() {
            firstResponder = nil
            focusedAccessibilityElement = nil
        }

        /// Records the current first responder and invokes a callback that includes a reference to the
        /// current first responder.
        ///
        /// - Parameter onRecord: The callback that is invoked when the current first responder
        /// has been recorded. The first responder if passed as an argument to this callback. If there is
        /// no first responder, this callback is not invoked.
        func recordFirstResponder(onRecord: (UIView) -> Void = { _ in }) {
            guard let viewController, viewController.isViewLoaded else {
                return
            }

            firstResponder = viewController.view.currentFirstResponder

            if let firstResponder {
                onRecord(firstResponder)
            }
        }

        func recordFocusedAccessibilityElement(onRecord: (NSObject) -> Void = { _ in }) {
            guard let viewController, viewController.isViewLoaded else {
                return
            }

            focusedAccessibilityElement = viewController.view.currentFocusedAccessibilityElement

            if let focusedAccessibilityElement {
                onRecord(focusedAccessibilityElement)
            }
        }
    }
}


extension UIView {

    fileprivate var isValidResponder: Bool {

        /// Must still be in a window to be a valid responder.
        guard window != nil else {
            return false
        }

        let views = sequence(first: self, next: \.superview)

        /// We cannot become first responder if any of our superviews are hidden.
        guard views.contains(where: \.isHidden) == false else {
            return false
        }

        /// We cannot become first responder if any of our superviews have no alpha.
        guard views.contains(where: { $0.alpha == 0 }) == false else {
            return false
        }

        return true
    }

    var currentFirstResponder: UIView? {

        guard let current = Self.findFirstResponder(), let current = current as? UIView else {
            return nil
        }

        if current.isDescendant(of: self) {
            return current
        } else {
            return nil
        }
    }

    fileprivate var currentFocusedAccessibilityElement: NSObject? {
        let current = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? UIView

        if let current, current.isDescendant(of: self) {
            return current
        } else {
            return nil
        }
    }

    /// This is a workaround for the fact that `UIResponder.currentFirstResponder` is not
    /// available in extensions.
    fileprivate static let findFirstResponder: () -> UIResponder? = {
        class BaseFirstResponderFinder {
            class func findFirstResponder() -> UIResponder? {
                nil
            }
        }

        class AppFirstResponderFinder: BaseFirstResponderFinder {

            @available(iOSApplicationExtension, unavailable)
            override class func findFirstResponder() -> UIResponder? {
                UIResponder.currentFirstResponder
            }
        }

        let isExtensionContext: Bool = // This is our best guess for "is this executable an extension?"
            if let _ = Bundle.main.infoDictionary?["NSExtension"] {
                true
            } else if Bundle.main.bundlePath.hasSuffix(".appex") {
                true
            } else {
                false
            }

        var finder: BaseFirstResponderFinder.Type {
            if isExtensionContext {
                BaseFirstResponderFinder.self
            } else {
                AppFirstResponderFinder.self
            }
        }

        return { finder.findFirstResponder() }
    }()
}
