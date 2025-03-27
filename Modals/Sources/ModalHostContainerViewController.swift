import UIKit

/// A `ModalHost` implementation that wraps another view controller.
///
/// You can use this view controller to easily add a modal host to the root of your app, by wrapping
/// an existing view controller that is at or near the root of the view controller hierarchy.
///
/// - Tag: ModalHostContainerViewController
///
@objc(MDLModalHostContainerViewController)
public final class ModalHostContainerViewController: UIViewController, ModalHost, ToastPresentationViewControllerDelegate {
    @objc public let content: UIViewController

    let modalPresentation: ModalPresentationViewController
    let toastPresentation: ToastPresentationViewController


    /// This property is used to provide a convenience that allows one to present a `ModalHostContainerViewController`
    /// over another modal host using vanilla UIKit presentation which can assist with incremental migration of the
    /// Modals framework.
    @_spi(ModalsImplementation)
    public weak var ancestorModalPresentationView: UIView? {
        didSet {
            modalPresentation.ancestorPresentationView = ancestorModalPresentationView
            /// This *must* be the MODAL presentation view, and not the toast one. We use this view to determine
            /// how to lay things out, and need a valid safe area. The toast one gets removed from the view
            /// hierarchy when not used, so cannot be used.
            toastPresentation.ancestorPresentationView = ancestorModalPresentationView
        }
    }

    private var needsModalUpdate = true
    private var isInModalUpdate = false

    var logger = ModalsLogging.logger

    /// Determines whether we should convert frames given to `modalPresentation` to our own coordinate space. Doing so
    /// while we're transitioning can cause issues, since our frame is moving relative to `_presentingModalPresenter`.
    private var shouldConvertModalPresentationFrames: Bool {
        transitionCoordinator == nil
    }

    public var presentationFilter: ModalPresentationFilter? {
        didSet {
            if presentationFilter?.identifier != oldValue?.identifier {
                setNeedsModalUpdate()
            }
        }
    }

    /// Create an instance that wraps another view controller.
    public convenience init(
        content: UIViewController,
        toastContainerStyle: ToastContainerPresentationStyleProvider,
        shouldPassthroughToasts: Bool = true
    ) {
        self.init(
            content: content,
            toastContainerStyle: toastContainerStyle,
            presentationFilter: shouldPassthroughToasts ? .passThroughToasts : nil
        )
    }

    /// Create an instance that wraps another view controller.
    public init(
        content: UIViewController,
        toastContainerStyle: ToastContainerPresentationStyleProvider,
        presentationFilter: ModalPresentationFilter?
    ) {
        self.content = content
        modalPresentation = ModalPresentationViewController(content: content)
        toastPresentation = ToastPresentationViewController(styleProvider: toastContainerStyle)
        self.presentationFilter = presentationFilter

        super.init(nibName: nil, bundle: nil)

        addChild(modalPresentation)
        modalPresentation.didMove(toParent: self)

        addChild(toastPresentation)
        toastPresentation.didMove(toParent: self)
        toastPresentation.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = ModalHostView(
            frame: content.view.frame,
            sizeThatFits: { [unowned content] size in
                content.view.sizeThatFits(size)
            },
            ancestorPresentationView: { [weak self] in
                self?.ancestorModalPresentationView
            },
            presentationViews: { [unowned modalPresentation, unowned toastPresentation] in
                [modalPresentation, toastPresentation].map { $0.view }
            }
        )

        // Match the UIKit default for a view controllers view. Not doing so can cause unexpected layout behavior.
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        modalPresentation.view.frame = view.bounds
        view.addSubview(modalPresentation.view)
        toastPresentation.view.frame = view.bounds
        view.addSubview(toastPresentation.view)

        addOrRemoveToastPresentationSubviewIfNecessary(
            hasVisiblePresentations: toastPresentation.hasVisiblePresentations
        )
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        updatePreferredContentSize()
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        modalPresentation.view.frame = view.bounds
        toastPresentation.view.frame = view.bounds

        updateModalsIfNeeded()
    }

    public override var childForStatusBarStyle: UIViewController? {
        modalPresentation
    }

    public override var childForStatusBarHidden: UIViewController? {
        modalPresentation
    }

    public override var childForHomeIndicatorAutoHidden: UIViewController? {
        modalPresentation
    }

    public override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        modalPresentation
    }

    public override var childViewControllerForPointerLock: UIViewController? {
        modalPresentation
    }

    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        modalPresentation.preferredStatusBarUpdateAnimation
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        modalPresentation.supportedInterfaceOrientations
    }

    public override var isModalInPresentation: Bool {
        get {
            super.isModalInPresentation || modalPresentation.isModalInPresentation
        }
        set {
            super.isModalInPresentation = newValue
        }
    }

    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        updatePreferredContentSize()
    }

    private func updatePreferredContentSize() {
        let preferredContentSize = modalPresentation.preferredContentSize

        guard self.preferredContentSize != preferredContentSize else { return }

        self.preferredContentSize = preferredContentSize
    }

    // MARK: ModalHost

    public func setNeedsModalUpdate() {
        needsModalUpdate = true

        viewIfLoaded?.setNeedsLayout()
        modalPresentation.viewIfLoaded?.setNeedsLayout()

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

        if let presentationFilter, hasAncestorModalHost {
            modalList = presentationFilter.presentedLocally(modalList)
        }

        modalPresentation.update(modals: modalList.modals)
        toastPresentation.update(
            toasts: modalList.toasts,
            // Only respect toast safe are insets if there are no modals.
            safeAreaAnchors: modalList.modals.isEmpty ? modalList.toastSafeAreaAnchors : []
        )
    }

    /// We need to override this method since we're handling all our children's modals.
    public override func aggregateModals() -> ModalList {
        guard let presentationFilter, hasAncestorModalHost else {
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
        presentationFilter != nil
    }

    // MARK: ToastPresentationViewControllerDelegate

    public func toastPresentationViewControllerDidChange(hasVisiblePresentations: Bool) {
        guard isViewLoaded else { return }

        addOrRemoveToastPresentationSubviewIfNecessary(hasVisiblePresentations: hasVisiblePresentations)
    }

    private func addOrRemoveToastPresentationSubviewIfNecessary(hasVisiblePresentations: Bool) {
        let isAddedAsSubview = toastPresentation.view.superview != nil
        if
            hasVisiblePresentations,
            isAddedAsSubview == false
        {
            toastPresentation.view.frame = view.bounds
            view.addSubview(toastPresentation.view)
            toastPresentation.view.layoutIfNeeded()
        } else if
            hasVisiblePresentations == false,
            isAddedAsSubview
        {
            toastPresentation.view.removeFromSuperview()
        }
    }
}

private final class ModalHostView: UIView {
    private let passthroughSizeThatFits: (CGSize) -> CGSize
    private let ancestorPresentationView: () -> UIView?
    private let presentationViews: () -> [UIView]

    init(
        frame: CGRect,
        sizeThatFits: @escaping (CGSize) -> CGSize,
        ancestorPresentationView: @escaping () -> UIView?,
        presentationViews: @escaping () -> [UIView]
    ) {
        self.ancestorPresentationView = ancestorPresentationView
        self.presentationViews = presentationViews
        passthroughSizeThatFits = sizeThatFits

        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        passthroughSizeThatFits(size)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for view in presentationViews().reversed() {
            if let view = view.hitTest(convert(point, to: view), with: event) {
                return view
            }
        }

        return nil
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let result = super.point(inside: point, with: event)

        if !result, let ancestorPresentationView = ancestorPresentationView() {
            let point = convert(point, to: ancestorPresentationView)
            return ancestorPresentationView.point(inside: point, with: event)
        }

        return result
    }
}
