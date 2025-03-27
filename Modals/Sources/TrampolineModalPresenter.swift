import UIKit
import ViewEnvironment
@_spi(ViewEnvironmentWiring) import ViewEnvironmentUI

/// Concrete implementation of `ModalPresenter` and `ToastPresenter` that notifies the nearest modal host with a call to
/// `ModalHost.setNeedsModalUpdate` after a modal is presented or dismissed.
final class TrampolineModalPresenter: ModalPresenter, ToastPresenter {
    private weak var owner: UIViewController?

    private var modals: [StoredModal] = []

    private var toasts: [StoredToast] = []

    private var ownerName: String {
        owner?.debugDescription ?? "unknown view controller"
    }

    private var environmentUpdateObservationLifetime: ViewEnvironmentUpdateObservationLifetime?

    init(owner: UIViewController) {
        self.owner = owner

        // Listen for environment updates
        environmentUpdateObservationLifetime = owner.addEnvironmentNeedsUpdateObserver { [weak self] environment in
            guard let self else { return }

            for node in propagationNodes() {
                node.setNeedsEnvironmentUpdate()
            }

            setModalHostNeedsUpdate(requiringModalHost: false)
        }
    }

    func setModalHostNeedsUpdate(requiringModalHost modalHostRequired: Bool) {
        guard let owner else {
            return
        }

        guard let host = owner.modalHost else {
            if modalHostRequired {
                ModalHostAsserts.noFoundModalHostFatalError(in: owner)
            } else {
                return
            }
        }

        host.setNeedsModalUpdate()
    }

    func present(
        _ viewController: UIViewController,
        style: ModalPresentationStyleProvider,
        info: ModalInfo,
        completion: (() -> Void)?
    ) -> ModalLifetime {
        present(
            viewController: viewController,
            storingIn: \.modals,
            environmentCustomizer: { environment in
                let resolvedStyle = style.presentationStyle(for: environment)
                resolvedStyle.customize(environment: &environment)
            }
        ) { propagationNode in
            StoredModal(
                content: viewController,
                propagationNode: propagationNode,
                presentationStyleProvider: style,
                info: info,
                onDidPresent: completion
            )
        }
    }

    func present(
        _ viewController: UIViewController,
        style: ToastPresentationStyleProvider,
        accessibilityAnnouncement: String
    ) -> ModalLifetime {
        present(viewController: viewController, storingIn: \.toasts) { propagationNode in
            StoredToast(
                content: viewController,
                propagationNode: propagationNode,
                presentationStyleProvider: style,
                accessibilityAnnouncement: accessibilityAnnouncement
            )
        }
    }

    func presentedModals(for environment: ViewEnvironment) -> [PresentableModal] {
        modals.map { $0.presentableModal(for: environment) }
    }

    func presentedToasts(for environment: ViewEnvironment) -> [PresentableToast] {
        toasts.map { $0.presentableToast(for: environment) }
    }

    private func present<Item: StoredItem>(
        viewController: UIViewController,
        storingIn itemsKeyPath: ReferenceWritableKeyPath<TrampolineModalPresenter, [Item]>,
        environmentCustomizer: ((inout ViewEnvironment) -> Void)? = nil,
        item itemProvider: (ModalEnvironmentPropagationNode) -> Item
    ) -> ModalLifetime {
        guard let owner else {
            fatalError(
                """
                No owning view controller was found when attempting to present \(Item.typeName). \
                This is not expected to be nil, and indicates an error in the Modals framework.
                """
            )
        }

        precondition(
            !self[keyPath: itemsKeyPath].contains(where: { $0.viewController === viewController }),
            "\(Item.typeName) is already being presented by \(ownerName)"
        )

        let propagationNode = ModalEnvironmentPropagationNode(
            presentingAncestor: owner,
            presentedViewController: viewController,
            environmentCustomizer: environmentCustomizer,
            initialEnvironment: owner.environment
        )

        let item = itemProvider(propagationNode)

        self[keyPath: itemsKeyPath].append(item)
        setModalHostNeedsUpdate(requiringModalHost: true)

        // Wire up upward environment propagation (we need to set it to `nil` first
        // in case we presented this view controller already).
        //
        // This node should live as long as the view controller, outliving the `StoredItem` types
        // we track on this presenter. So the view controller keeps a strong reference.
        item.viewController.environmentAncestorOverride = nil
        item.viewController.environmentAncestorOverride = { propagationNode }
        item.viewController.setNeedsEnvironmentUpdate()

        // Capture a reference to the host in the lifetime token dismiss closure so we can dismiss
        // the modal in the case where its owner is deallocated before it token is (e.g., this can
        // happen when a view controller presenting a modal is popped).
        let host = ModalHostAsserts.ensureModalHost(in: owner)

        return LifetimeToken(ownerName: ownerName) { [weak self, weak host] in

            // This token is typically held by the presenting view controller,
            // which is a descendent of the modal host, and strongly referenced by it.
            // To avoid a reference cycle, reference the host weakly.

            host?.setNeedsModalUpdate()

            guard let self else {
                return
            }
            guard let index = self[keyPath: itemsKeyPath]
                .firstIndex(where: { $0.viewController === viewController })
            else {
                preconditionFailure("Cannot find \(Item.typeName) to dismiss from \(ownerName)")
            }
            self[keyPath: itemsKeyPath].remove(at: index)
        }
    }

    private func propagationNodes() -> [ViewEnvironmentPropagating] {
        modals.map { $0.propagationNode }
            + toasts.map { $0.propagationNode }
    }
}

extension TrampolineModalPresenter {
    private final class LifetimeToken: ModalLifetime {
        private let ownerName: String
        private var onDismiss: (() -> Void)?

        init(ownerName: String, onDismiss: @escaping () -> Void) {
            self.ownerName = ownerName
            self.onDismiss = onDismiss
        }

        deinit {
            onDismiss?()
        }

        func dismiss() {
            guard let onDismiss else {
                preconditionFailure("Modal was already dismissed from \(ownerName)")
            }
            self.onDismiss = nil
            onDismiss()
        }
    }
}

extension TrampolineModalPresenter {
    final class StoredModal: StoredItem {
        let viewController: UIViewController
        let propagationNode: ModalEnvironmentPropagationNode
        let presentationStyleProvider: ModalPresentationStyleProvider
        let info: ModalInfo
        let onDidPresent: (() -> Void)?

        init(
            content: UIViewController,
            propagationNode: ModalEnvironmentPropagationNode,
            presentationStyleProvider: ModalPresentationStyleProvider,
            info: ModalInfo,
            onDidPresent: (() -> Void)?
        ) {
            viewController = content
            self.propagationNode = propagationNode
            self.presentationStyleProvider = presentationStyleProvider
            self.info = info
            self.onDidPresent = onDidPresent
        }

        func presentableModal(for environment: ViewEnvironment) -> PresentableModal {
            let style = presentationStyleProvider.presentationStyle(for: environment)

            return PresentableModal(
                viewController: viewController,
                presentationStyle: style,
                info: info,
                onDidPresent: onDidPresent
            )
        }

        static var typeName: String { "Modal" }
    }

    final class StoredToast: StoredItem {
        let viewController: UIViewController
        let propagationNode: ModalEnvironmentPropagationNode
        let presentationStyleProvider: ToastPresentationStyleProvider
        let accessibilityAnnouncement: String

        init(
            content: UIViewController,
            propagationNode: ModalEnvironmentPropagationNode,
            presentationStyleProvider: ToastPresentationStyleProvider,
            accessibilityAnnouncement: String
        ) {
            viewController = content
            self.propagationNode = propagationNode
            self.presentationStyleProvider = presentationStyleProvider
            self.accessibilityAnnouncement = accessibilityAnnouncement
        }

        func presentableToast(for environment: ViewEnvironment) -> PresentableToast {
            let style = presentationStyleProvider.presentationStyle(for: environment)

            return PresentableToast(
                viewController: viewController,
                presentationStyle: style,
                accessibilityAnnouncement: accessibilityAnnouncement
            )
        }

        static var typeName: String { "Toast" }
    }
}

extension TrampolineModalPresenter {
    /// An environment propagation node to sit in between the presenting view controller and each
    /// presented modal. It caches the `ViewEnvironment`, so that if the propagation path is broken
    /// before the modal is dismissed (e.g. by an ancestor view controller being removed) the modal
    /// can still access the cached environment during any layouts that happen before its dismissal
    /// is completed.
    ///
    /// This node is owned by the presented modal view controller, through a strong reference in
    /// the `environmentAncestorOverride` wiring.
    ///
    final class ModalEnvironmentPropagationNode: ViewEnvironmentObserving {

        weak var presentingAncestor: UIViewController?
        weak var presentedViewController: UIViewController?
        var environmentCustomizer: ((inout ViewEnvironment) -> Void)?
        var lastEnvironment: ViewEnvironment

        init(
            presentingAncestor: UIViewController,
            presentedViewController: UIViewController,
            environmentCustomizer: ((inout ViewEnvironment) -> Void)?,
            initialEnvironment: ViewEnvironment
        ) {
            self.presentingAncestor = presentingAncestor
            self.presentedViewController = presentedViewController
            self.environmentCustomizer = environmentCustomizer
            lastEnvironment = initialEnvironment
        }

        func setNeedsEnvironmentUpdate() {
            if let presentingAncestor, presentingAncestor.modalHost != nil {
                lastEnvironment = presentingAncestor.environment
            }

            environmentDidChange()

            setNeedsEnvironmentUpdateOnAppropriateDescendants()
        }

        var defaultEnvironmentAncestor: ViewEnvironmentPropagating? {
            if presentingAncestor?.modalHost == nil {
                return nil
            }

            return presentingAncestor
        }

        var defaultEnvironmentDescendants: [ViewEnvironmentPropagating] {
            if let presentedViewController {
                return [presentedViewController]
            }
            return []
        }

        func customize(environment: inout ViewEnvironment) {
            if presentingAncestor?.modalHost == nil {
                // The ancestor has been removed. Use the cached environment.
                environment = lastEnvironment
            }
            environmentCustomizer?(&environment)
        }

        func setNeedsApplyEnvironment() {
            applyEnvironmentIfNeeded()
        }
    }
}

/// Common properties between stored modals and toasts.
private protocol StoredItem {

    var viewController: UIViewController { get }

    /// An environment propagation node that sits between the presenting VC (owner) and this modal.
    /// An environment observer installed on the owner with `addEnvironmentUpdateObserver()` will
    /// call  `setNeedsEnvironmentUpdate()` on this node whenever the owner's environment updates.
    var propagationNode: TrampolineModalPresenter.ModalEnvironmentPropagationNode { get }

    static var typeName: String { get }
}
