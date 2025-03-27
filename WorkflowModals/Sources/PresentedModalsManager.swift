import Modals
import UIKit
import WorkflowUI


typealias AnyPresentedModalsManager = PresentedModalsManager<AnyScreen, AnyScreen>


/// Manages the realization of modal and toast screens into a `ModalList` for `ModalContainer` and
/// `WorkflowModalListProvider`.
///
final class PresentedModalsManager<ModalContent: Screen, ToastContent: Screen> {

    /// The currently presented modals based on the screen.
    var presentedModals: [PresentedModal] = []

    /// The currently presented toasts based on the screen.
    var presentedToasts: [PresentedToast] = []

    init() {}

    private(set) var environment: ViewEnvironment = .empty

    func update(contents: Contents, environment: ViewEnvironment) {

        // Since keys are not guaranteed to be unique, we'll collect
        // them into a dictionary of key: [modals] and update them in order.
        var previousModals: [PresentationKey: [PresentedModal]] = .init(
            presentedModals.map { ($0.key, [$0]) },
            uniquingKeysWith: +
        )

        // Will contain the new set of presented screens by the end of this method.
        var newModals: [PresentedModal] = []

        for modal in contents.modals {
            let style = modal.presentationStyle(for: environment)

            let key = PresentationKey(
                modalKey: modal.key,
                kind: modal.kind(in: environment)
            )

            var environment = environment
            style.customize(environment: &environment)

            if let existing = previousModals[key]?.first {

                // We found a modal with a matching key to reuse, remove it from the previous
                // modals and update the view controller.
                previousModals[key]?.removeFirst()

                modal.content.update(
                    viewController: existing.viewController,
                    with: environment
                )

                let modal = PresentedModal(
                    key: key,
                    viewController: existing.viewController,
                    style: style,
                    info: modal.info
                )

                newModals.append(modal)

            } else {
                // No matching modal was found, so create a new view controller and modal.

                let newViewController = modal
                    .content
                    .buildViewController(in: environment)

                let modal = PresentedModal(
                    key: key,
                    viewController: newViewController,
                    style: style,
                    info: modal.info
                )

                newModals.append(modal)
            }
        }

        // Update our state to reflect the new screens post-update.
        presentedModals = newModals

        var previousToasts = Dictionary(presentedToasts.map { ($0.key, [$0]) }, uniquingKeysWith: +)
        var newToasts: [PresentedToast] = []

        for toast in contents.toasts {
            let style = toast.presentationStyle(for: environment)

            let key = PresentationKey(
                modalKey: toast.key,
                kind: toast.kind(in: environment)
            )

            if let existing = previousToasts[key]?.first {
                // We found a modal with a matching key to reuse, remove it from the previous
                // toasts and update the view controller.
                previousToasts[key]?.removeFirst()

                toast.content.update(
                    viewController: existing.viewController,
                    with: environment
                )

                let toast = PresentedToast(
                    key: key,
                    viewController: existing.viewController,
                    style: style,
                    accessibilityAnnouncement: toast.accessibilityAnnouncement
                )

                newToasts.append(toast)
            } else {
                // No matching toast was found, so create a new view controller and toast.
                let newViewController = toast
                    .content
                    .buildViewController(in: environment)

                let toast = PresentedToast(
                    key: key,
                    viewController: newViewController,
                    style: style,
                    accessibilityAnnouncement: toast.accessibilityAnnouncement
                )

                newToasts.append(toast)
            }
        }

        // Update our state to reflect the new screens post-update.
        presentedToasts = newToasts
    }
}


extension PresentedModalsManager {

    struct Contents {
        var modals: [Modal<ModalContent>]
        var toasts: [Toast<ToastContent>]
    }

    /// Wraps the information needed to present and update a Modal.
    final class PresentedModal {
        let key: PresentationKey
        let viewController: UIViewController
        let style: ModalPresentationStyle
        let info: ModalInfo

        var modal: PresentableModal {
            PresentableModal(
                viewController: viewController,
                presentationStyle: style,
                info: info,
                onDidPresent: nil
            )
        }

        init(
            key: PresentationKey,
            viewController: UIViewController,
            style: ModalPresentationStyle,
            info: ModalInfo
        ) {
            self.key = key
            self.viewController = viewController
            self.style = style
            self.info = info
        }
    }


    final class PresentedToast {
        let key: PresentationKey
        let viewController: UIViewController
        let style: ToastPresentationStyle
        let accessibilityAnnouncement: String

        var toast: PresentableToast {
            PresentableToast(
                viewController: viewController,
                presentationStyle: style,
                accessibilityAnnouncement: accessibilityAnnouncement
            )
        }

        init(
            key: PresentationKey,
            viewController: UIViewController,
            style: ToastPresentationStyle,
            accessibilityAnnouncement: String
        ) {
            self.key = key
            self.viewController = viewController
            self.style = style
            self.accessibilityAnnouncement = accessibilityAnnouncement
        }
    }

    /// A key that is salted by the type of the underlying `UIViewController`,
    /// so we can change the view controller if the backing type changes.
    struct PresentationKey: Hashable {

        var modalKey: AnyHashable
        var kind: ViewControllerDescription.KindIdentifier
    }
}
