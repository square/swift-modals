import Foundation
import UIKit

public enum ModalHostAsserts {

    /// ### Note
    ///
    /// The below use `@inline(never)` to ensure that the correct
    /// function name appears in crash reports and nothing is flattened
    /// into calling functions.

    /// Returns the `ModalHost` for the given view controller, asserting if one is not found.
    @inline(never) public static func ensureModalHost(in vc: UIViewController) -> ModalHost {

        if let host = vc.modalHost {
            return host
        }

        noFoundModalHostFatalError(in: vc)
    }

    /// Performs a fatal error based on the current state of the view controller to
    /// inform the developer (in both debug and release) that a modal host could not be found,
    /// and thus future behaviour would be undefined.
    @inline(never) public static func noFoundModalHostFatalError(in vc: UIViewController) -> Never {
        if let presenting = vc.presentingViewController {
            modalError_isInUIKitModal(in: vc, presenting: presenting)
        } else if vc.parent == nil {
            modalError_IsMissingParentViewController(in: vc)
        } else {
            modalError_IsInInvalidViewControllerHierarchy(in: vc)
        }
    }

    @inline(never)
    private static func modalError_isInUIKitModal(in vc: UIViewController, presenting: UIViewController) -> Never {
        fatalError(
            """
            Found a presentingViewController (\(presenting)) when attempting to find the modal host.

            '\(type(of: vc))' cannot present a view controller because it was presented using UIKit \
            modal presentation. Please update the presenting '\(type(of: vc.presentingViewController))' to use the \
            Modal framework for presentation.

            For more info, visit
            https://github.com/square/swift-modals/Documentation/tips.md
            """
        )
    }

    @inline(never)
    private static func modalError_IsMissingParentViewController(in vc: UIViewController) -> Never {

        fatalError(
            """
            '\(type(of: vc))' has no parent view controller, which means we cannot find a modal host.

            Modals cannot be presented or dismissed unless they are in a valid parent view controller \
            hierarchy in order to find the modal host. It is likely that this view controller was previously \
            in a valid view controller hierarchy, but that was since torn down.

            For more info, visit
            https://github.com/square/swift-modals/Documentation/tips.md
            """
        )
    }

    @inline(never)
    private static func modalError_IsInInvalidViewControllerHierarchy(in vc: UIViewController) -> Never {

        let viewControllers = upwardViewControllerHierarchy(in: vc).map { name in
            "   " + name
        }.joined(separator: "\n")

        fatalError(
            """
            The parent view controller hierarchy did not contain a modal host. The found hierarchy:
            \(viewControllers)

            Modals cannot be presented or dismissed unless they are in a valid parent
            view controller hierarchy (in order to find the modal host).

            It is likely that one of the following is true:

            1) This view controller was previously in a valid view controller hierarchy, but that was since torn down.

            2) This view controller is not in a valid hierarchy, and hence cannot find a modal host.
               a) We recommend checking the integrity of your view controller hierarchy (eg, the parent/child relationships).

            3) The view controller is presented in a new window that lacks a modal host.
               Note: We recommend not presenting UI in new windows for many reasons,
               and instead converting these presentations to the modals framework.

            For more info, visit
            https://github.com/square/swift-modals/Documentation/tips.md
            """
        )
    }

    private static func upwardViewControllerHierarchy(in vc: UIViewController) -> [String] {
        var parents = [String]()

        var current: UIViewController? = vc

        repeat {
            if let current {
                let typeName = String(describing: type(of: current))
                parents.append(typeName)
            }

            current = current?.parent

        } while current != nil

        return parents
    }
}
