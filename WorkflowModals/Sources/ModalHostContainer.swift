@_spi(ModalsImplementation) import Modals
import UIKit
import WorkflowUI

/// A [ModalHost](x-source-tag://ModalHost) implementation for use in Workflows.
///
/// [ModalContainer](x-source-tag://ModalContainer) uses the modal system to
/// trampoline modals to a [ModalHost](x-source-tag://ModalHost), which must be installed somewhere
/// in your hierarchy. In a pure workflow application, you should install this container at the root
/// of your app.
///
/// In a hybrid application, you should install a
/// [ModalHostContainerViewController](x-source-tag://ModalHostContainerViewController) instead,
/// in which case you do not need to use this container.
///
/// To add a host to your Workflow hierarchy, you can use the extension on `Screen` to easily wrap
/// an existing screen:
///
/// ```swift
///     return MyRootScreen()
///         .modalHost()
/// ```
///
/// Or you can map the rendering of your root Workflow:
///
/// ```swift
///     let rootWorkflow = MyRootWorkflow()
///         .mapRendering(ModalHostContainer.init)
/// ```
///
/// - Tag: ModalHostContainer
///
public struct ModalHostContainer<Content> {

    /// The wrapped content of the modal host.
    public var content: Content

    /// The toast container style provider of the modal host.
    public var toastContainerStyle: ToastContainerPresentationStyleProvider

    /// Defines which modals should be presented locally and which should be forwarded to
    /// an ancestor modal host. If `nil`, all modals are presented locally.
    fileprivate var presentationFilter: ModalPresentationFilter?

    /// Create a new host wrapping the provided content.
    public init(
        content: Content,
        toastContainerStyle: ToastContainerPresentationStyleProvider
    ) {
        self = .init(
            content: content,
            toastContainerStyle: toastContainerStyle,
            presentationFilter: .passThroughToasts
        )
    }

    /// Create a new host wrapping the provided content.
    public init(
        content: Content,
        toastContainerStyle: ToastContainerPresentationStyleProvider,
        shouldPassthroughToasts: Bool
    ) {
        self = .init(
            content: content,
            toastContainerStyle: toastContainerStyle,
            presentationFilter: shouldPassthroughToasts ? .passThroughToasts : nil
        )
    }

    /// Create a new host wrapping the provided content. The host will present modals that match the
    /// provided filter or all modals if none is provided.
    public init(
        content: Content,
        toastContainerStyle: ToastContainerPresentationStyleProvider,
        presentationFilter: ModalPresentationFilter?
    ) {
        self.content = content
        self.toastContainerStyle = toastContainerStyle
        self.presentationFilter = presentationFilter
    }
}

extension ModalHostContainer {
    public struct PresentationFilter {
        /// A unique identifier for the filter. A change in identifier should trigger a re-evaluation of modal
        /// presentation.
        let identifier: AnyHashable

        /// `true` if the modal should be presented locally and `false` if it should be forwarded
        /// to an ancestor.
        let modalPredicate: (PresentableModal) -> Bool

        /// `true` if a toast should be presented locally and `false` if it should be forwarded
        /// to an ancestor.
        let toastPredicate: (PresentableToast) -> Bool

        func presentedLocally(_ list: ModalList) -> ModalList {
            ModalList(
                modals: list.modals.filter(modalPredicate),
                toasts: list.toasts.filter(toastPredicate),
                toastSafeAreaAnchors: list.toastSafeAreaAnchors
            )
        }

        func presentedByAncestor(_ list: ModalList) -> ModalList {
            ModalList(
                modals: list.modals.filter { !modalPredicate($0) },
                toasts: list.toasts.filter { !toastPredicate($0) },
                toastSafeAreaAnchors: list.toastSafeAreaAnchors
            )
        }

        static var passThroughToasts: PresentationFilter {
            .init(
                identifier: "pass-through-toasts",
                modalPredicate: { _ in true },
                toastPredicate: { _ in false }
            )
        }

        public static func containsUniqueKey(
            _ key: (some UniqueModalInfoKey).Type
        ) -> PresentationFilter {
            .init(
                identifier: ObjectIdentifier(key),
                modalPredicate: { $0.info.contains(key) },
                toastPredicate: { _ in false }
            )
        }
    }
}

extension ModalHostContainer: Screen where Content: Screen {
    public func viewControllerDescription(environment: ViewEnvironment) -> ViewControllerDescription {
        ViewController.description(
            for: self,
            environment: environment,
            performInitialUpdate: false
        )
    }

    // TODO: This should be extracted from `ModalHostContainer<Content>` so its type isnt dependent on `<Content>`.

    final class ViewController: ScreenViewController<ModalHostContainer>, ModalHost, ToastPresentationViewControllerDelegate {
        private(set) var content: UIViewController
        let modalPresentationController: ModalPresentationViewController
        let toastPresentationController: ToastPresentationViewController

        private var needsModalUpdate = true
        private var isInModalUpdate = false

        required init(screen: ModalHostContainer, environment: ViewEnvironment) {
            content = screen
                .content
                .buildViewController(in: environment)

            modalPresentationController = ModalPresentationViewController(content: content)

            toastPresentationController = ToastPresentationViewController(
                styleProvider: .init(screen.toastContainerStyle.style(for: environment))
            )

            super.init(screen: screen, environment: environment)

            addChild(modalPresentationController)
            modalPresentationController.didMove(toParent: self)

            addChild(toastPresentationController)
            toastPresentationController.didMove(toParent: self)
            toastPresentationController.delegate = self
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            modalPresentationController.view.frame = view.bounds
            view.addSubview(modalPresentationController.view)

            addOrRemoveToastPresentationSubviewIfNecessary(
                hasVisiblePresentations: toastPresentationController.hasVisiblePresentations
            )

            updatePreferredContentSize()
        }

        public override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            modalPresentationController.view.frame = view.bounds
            toastPresentationController.view.frame = view.bounds

            updateModalsIfNeeded()
        }

        override func screenDidChange(from previousScreen: ModalHostContainer, previousEnvironment: ViewEnvironment) {

            update(child: \.content, with: screen.content, in: environment)

            toastPresentationController.styleProvider = .init(
                screen.toastContainerStyle.style(for: environment)
            )

            if previousScreen.presentationFilter?.identifier != screen.presentationFilter?.identifier {
                setNeedsModalUpdate()
            }
        }

        override var childForStatusBarStyle: UIViewController? {
            modalPresentationController
        }

        override var childForStatusBarHidden: UIViewController? {
            modalPresentationController
        }

        override var childForHomeIndicatorAutoHidden: UIViewController? {
            modalPresentationController
        }

        override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
            modalPresentationController
        }

        override var childViewControllerForPointerLock: UIViewController? {
            modalPresentationController
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            modalPresentationController.supportedInterfaceOrientations
        }

        override var isModalInPresentation: Bool {
            get {
                super.isModalInPresentation || modalPresentationController.isModalInPresentation
            }
            set {
                super.isModalInPresentation = newValue
            }
        }

        public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
            super.preferredContentSizeDidChange(forChildContentContainer: container)

            updatePreferredContentSize()
        }

        // MARK: ModalHost

        func setNeedsModalUpdate() {
            needsModalUpdate = true

            viewIfLoaded?.setNeedsLayout()
            modalPresentationController.viewIfLoaded?.setNeedsLayout()

            if hasPresentationFilter, let ancestorModalHost {
                // Some modals may be forwarded to an ancestor host.
                // Inform it so that it may update.
                ancestorModalHost.setNeedsModalUpdate()
            }
        }

        private func updateModalsIfNeeded() {
            guard needsModalUpdate, !isInModalUpdate else { return }
            isInModalUpdate = true
            defer { isInModalUpdate = false }
            needsModalUpdate = false

            var modalList = content.aggregateModals()

            if let presentationFilter = screen.presentationFilter, hasAncestorModalHost {
                modalList = presentationFilter.presentedLocally(modalList)
            }

            modalPresentationController.update(modals: modalList.modals)
            toastPresentationController.update(
                toasts: modalList.toasts,
                // Only respect toast safe are insets if there are no modals.
                safeAreaAnchors: modalList.modals.isEmpty ? modalList.toastSafeAreaAnchors : []
            )
        }

        /// We need to override this method since we're handling all our children's modals.
        override func aggregateModals() -> ModalList {
            guard let presentationFilter = screen.presentationFilter, hasAncestorModalHost else {
                // No modals can be forwarded. Do not aggregate and instead
                // handle presentation locally.
                return ModalList()
            }

            // Some modals should be forwarded. Pass them through to aggregation.
            let modalList = content.aggregateModals()
            return presentationFilter.presentedByAncestor(modalList)
        }

        private var ancestorModalHost: ModalHost? {
            parent?.modalHost
        }

        private var hasAncestorModalHost: Bool {
            ancestorModalHost != nil
        }

        private var hasPresentationFilter: Bool {
            screen.presentationFilter != nil
        }

        // MARK: ToastPresentationViewControllerDelegate

        func toastPresentationViewControllerDidChange(hasVisiblePresentations: Bool) {
            guard isViewLoaded else { return }

            addOrRemoveToastPresentationSubviewIfNecessary(hasVisiblePresentations: hasVisiblePresentations)
        }

        private func addOrRemoveToastPresentationSubviewIfNecessary(hasVisiblePresentations: Bool) {
            let isAddedAsSubview = toastPresentationController.view.superview != nil
            if
                hasVisiblePresentations,
                isAddedAsSubview == false
            {
                toastPresentationController.view.frame = view.bounds
                view.addSubview(toastPresentationController.view)
                toastPresentationController.view.layoutIfNeeded()
            } else if
                hasVisiblePresentations == false,
                isAddedAsSubview
            {
                toastPresentationController.view.removeFromSuperview()
            }
        }

        private func updatePreferredContentSize() {
            let preferredContentSize = content.preferredContentSize

            guard self.preferredContentSize != preferredContentSize else { return }

            self.preferredContentSize = preferredContentSize
        }
    }
}

extension ModalHostContainer: SingleScreenContaining where Content: Screen {
    public var primaryScreen: Screen {
        content
    }
}

extension Screen {

    /// Convenience method for wrapping a `Screen` in a [ModalHostContainer](x-source-tag://ModalHostContainer).
    ///
    public func modalHost(
        toastContainerStyle: ToastContainerPresentationStyleProvider
    ) -> ModalHostContainer<Self> {
        ModalHostContainer(
            content: self,
            toastContainerStyle: toastContainerStyle
        )
    }

    /// Convenience method for wrapping a `Screen` in a [ModalHostContainer](x-source-tag://ModalHostContainer)
    /// which presents modals that contain the given unique key in their `.info` dictionaries.
    ///
    public func modalHost(
        toastContainerStyle: ToastContainerPresentationStyleProvider,
        presentingOnlyModalsContaining key: (some UniqueModalInfoKey).Type
    ) -> ModalHostContainer<Self> {
        ModalHostContainer(
            content: self,
            toastContainerStyle: toastContainerStyle,
            presentationFilter: .containsUniqueKey(key)
        )
    }
}
