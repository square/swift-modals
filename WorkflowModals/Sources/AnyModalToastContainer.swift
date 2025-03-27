import Modals
import UIKit
import WorkflowUI

@_spi(WorkflowModalsImplementation)
public struct AnyModalToastContainer: Screen {

    var base: AnyScreen

    public var modals: [Modal<AnyScreen>]

    public var toasts: [Toast<AnyScreen>]

    public init(
        base: AnyScreen,
        modals: [Modal<AnyScreen>] = [],
        toasts: [Toast<AnyScreen>] = []
    ) {
        self.base = base
        self.modals = modals
        self.toasts = toasts
    }

    public func viewControllerDescription(environment: ViewEnvironment) -> ViewControllerDescription {
        AnyModalToastContainerViewController.description(for: self, environment: environment)
    }
}

extension AnyModalToastContainer: SingleScreenContaining {
    public var primaryScreen: Screen {
        // toasts do not represent a new "screen" semantically so we always return the base
        // or the top-most modal
        modals.last?.content ?? base
    }
}

/// The view controller used to represent a `ModalContainer<BaseContent, ModalContent>` screen.
/// It converts the provide modal screens into view controllers, for return from the `aggregateModals()` function.
///
/// ## A Note On `ScreenViewController<AnyModalContainer>`
/// You might be wondering why the view controller inherits from `ScreenViewController<AnyModalContainer>`,
/// instead of just being nested as `ModalContainer<BaseContent, ModalContent>.ViewController`. This is to prevent
/// the view controller (and thus, every modal within it) from being re-created when the `BaseContent` or `ModalContent` type of a
/// `ModalContainer` changes.
///
/// For example, imagine this code that changes the `BaseContent` type of the returned modal container based on some flag:
/// ```
/// func myScreen() -> AnyScreen {
///     if self.foo {
///         return AnyScreen(ModalContainer<MyBaseScreen1, MyModalsType>(...))
///     } else {
///         return AnyScreen(ModalContainer<MyBaseScreen2, MyModalsType>(...))
///     }
/// }
/// ```
/// If we did not type erase the `BaseContent` and `ModalContent` to `AnyModalContainer`, when the path of the `if` statement
/// changes, the entire backing view controller type would change, and thus be re-created. By type erasing, the
/// view controller will remain.
///
@_spi(WorkflowModalsImplementation)
public final class AnyModalToastContainerViewController: ScreenViewController<AnyModalToastContainer> {

    // This variable is used to keep track of whether we need to notify the modal host of an
    // update. This is used since we might be rendered without a modal host, but want to notify
    // the host of our modals once we're in one.
    private var needsModalHostUpdate: Bool

    // When we're removed from the view (controller) hierarchy, we need to notify our modal host to update our
    // modals with an empty modal list. This bool indicates that `aggregateModals` should return an empty array.
    private var isBeingRemovedFromHierarchy = false

    // The manager is lazily instantiated and updated when aggregateModals is first called so that it is more likely to
    // use a complete and valid environment during the initial modal list resolution. We may, for example, be in a
    // hierarchy that contains environment mutations above the root `WorkflowHostingController` for this `Screen` which
    // would not be present on first build, but needs to be updated at some point. We cannot rely on
    // `screenDidChange(...)` since `AnyModalToastContainer`'s `ViewControllerDescription` sets `performInitialUpdate`
    // to `false`.
    private var manager: AnyPresentedModalsManager?

    private(set) var baseViewController: UIViewController

    public override var wrappedContentViewController: UIViewController? {
        baseViewController
    }

    public override func aggregateModals() -> ModalList {
        if isBeingRemovedFromHierarchy {
            return ModalList(modals: [])
        }

        // Lazily instantiate and update the manager if needed.
        let manager: AnyPresentedModalsManager
        if let existingManager = self.manager {
            manager = existingManager
        } else {
            manager = AnyPresentedModalsManager()
            self.manager = manager
            updatePresentedModals(
                manager: manager,
                environment: environment
            )
        }

        let aggregateModals = baseViewController.aggregateModals() + aggregatePresenterModals()

        let presentedModalsAndAggregates = manager.presentedModals.map { modal in
            (modal.modal, modal.viewController.aggregateModals())
        }

        return ModalList(
            modals: aggregateModals.modals
                + presentedModalsAndAggregates.flatMap { [$0] + $1.modals },
            toasts: manager.presentedToasts.map { $0.toast }
                + aggregateModals.toasts
                + presentedModalsAndAggregates.flatMap { $1.toasts },
            toastSafeAreaAnchors: aggregateModals.toastSafeAreaAnchors
        )
    }

    public required init(screen: AnyModalToastContainer, environment: ViewEnvironment) {
        needsModalHostUpdate = !(screen.modals.isEmpty && screen.toasts.isEmpty)

        baseViewController = screen
            .base
            .buildViewController(in: environment)

        super.init(screen: screen, environment: environment)

        addChild(baseViewController)
        baseViewController.didMove(toParent: self)
    }

    public override func loadView() {
        view = View(willMoveToWindow: { [weak self] window in
            self?.isBeingRemovedFromHierarchy = window == nil

            if window == nil {
                self?.setNeedsModalHostUpdate()
            }
        })
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        baseViewController.view.frame = view.bounds
        view.addSubview(baseViewController.view)

        // Match the UIKit default for a view controllers view. Not doing so can cause unexpected layout behavior.
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        preferredContentSize = baseViewController.preferredContentSize
    }

    public override func screenDidChange(
        from previousScreen: AnyModalToastContainer,
        previousEnvironment: ViewEnvironment
    ) {
        super.screenDidChange(from: previousScreen, previousEnvironment: previousEnvironment)

        let environment = environment

        update(child: \.baseViewController, with: screen.base, in: environment)

        // If the manager hasn't been initialized yet that means an aggregation hasn't occurred yet. We'll wait until an
        // aggregation occurs and perform the initial update in `aggregateModals`' lazy update of the manager.
        if let manager {
            updatePresentedModals(
                manager: manager,
                environment: environment
            )
        }

        setNeedsModalHostUpdate()
    }

    // Sets `needsModalHostUpdate` to true and attempts to update the host immediately. If there
    // is no host, we try again on the next `viewDidLayoutSubviews`.
    private func setNeedsModalHostUpdate() {
        needsModalHostUpdate = true
        updateModalHostIfNeeded()
    }

    private func updateModalHostIfNeeded() {
        guard needsModalHostUpdate else {
            return
        }

        guard let host = modalHost else {

            // If we're not installed the view controller hierarchy, we don't expect to find a
            // host, but if we are and we don't have a modal host, that's a programmer error
            // since we cannot present our modals.

            guard isViewLoaded else {
                return
            }

            guard view.window != nil else {
                return
            }

            ModalHostAsserts.noFoundModalHostFatalError(in: self)
        }

        host.setNeedsModalUpdate()
        needsModalHostUpdate = false
    }

    private func updatePresentedModals(
        manager: AnyPresentedModalsManager,
        environment: ViewEnvironment
    ) {
        manager.update(
            contents: .init(
                modals: screen.modals,
                toasts: screen.toasts
            ),
            environment: environment
        )
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        baseViewController.view.frame = view.bounds
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateModalHostIfNeeded()
    }

    public override var childForStatusBarStyle: UIViewController? {
        baseViewController
    }

    public override var childForStatusBarHidden: UIViewController? {
        baseViewController
    }

    public override var childForHomeIndicatorAutoHidden: UIViewController? {
        baseViewController
    }

    public override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        baseViewController
    }

    public override var childViewControllerForPointerLock: UIViewController? {
        baseViewController
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        baseViewController.supportedInterfaceOrientations
    }

    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        guard container === baseViewController,
              container.preferredContentSize != preferredContentSize
        else {
            return
        }

        preferredContentSize = container.preferredContentSize
    }

    /// A key that is salted by the type of the underlying `UIViewController`,
    /// so we can change the view controller if the backing type changes.
    struct PresentationKey: Hashable {

        var modalKey: AnyHashable
        var kind: ViewControllerDescription.KindIdentifier

    }

    private final class View: UIView {
        var willMoveToWindow: (UIWindow?) -> Void

        init(willMoveToWindow: @escaping (UIWindow?) -> Void) {
            self.willMoveToWindow = willMoveToWindow
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            willMoveToWindow(newWindow)
        }
    }
}
