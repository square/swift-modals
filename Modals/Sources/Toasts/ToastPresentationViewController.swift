import UIKit
import ViewEnvironment
import ViewEnvironmentUI


/// This view controller is capable of presenting the toasts in a `ModalList`.
///
/// Generally you should not need to use this view controller directly. Instead, use `ModalHostContainerViewController`
/// to wrap your root view controller.
///
/// If you need to add `ModalHost` conformance to your own view controller, you can embed this view controller to handle
/// the presentation.
///
/// ## See Also:
/// - [ModalHostContainerViewController](x-source-tag://ModalHostContainerViewController)
///
public final class ToastPresentationViewController:
    UIViewController,
    ViewEnvironmentObserving
{

    /// The style provider used by this presentation view controller.
    ///
    public var styleProvider: ToastContainerPresentationStyleProvider {
        didSet { setNeedsEnvironmentUpdate() }
    }

    /// True if this any toasts are currently being presented.
    ///
    public var hasToasts: Bool { !presentations.isEmpty }

    /// An array of the view controllers currently being presented as toasts.
    ///
    public var presentedViewControllers: [UIViewController] {
        presentations
            .filter { !$0.state.isExiting }
            .map(\.viewController)
    }

    /// Whether any toasts are currently visible.
    ///
    public var hasVisiblePresentations: Bool { presentations.isEmpty == false }

    public weak var delegate: ToastPresentationViewControllerDelegate?

    /// Use this property to assign an ancestor `ToastPresentationViewController` view that we should use to determine
    /// the frame of our presentations.
    @_spi(ModalsImplementation)
    public weak var ancestorPresentationView: UIView?

    /// The view to use for laying out presentations - either `ancestorPresentationView` if it exists, or our own view.
    var presentationView: UIView {
        ancestorPresentationView ?? view
    }

    private(set) var style: ToastContainerPresentationStyle?

    var presentations: [Presentation] = [] {
        didSet {
            // The delegate call back when visible presentations become present is called in `update(toasts:)` before we
            // attempt to layout toasts.
            if
                oldValue.isEmpty == false,
                presentations.isEmpty
            {
                delegate?.toastPresentationViewControllerDidChange(hasVisiblePresentations: false)
            }
        }
    }

    private(set) var safeAreaAnchorInsets: UIEdgeInsets = .zero

    let keyboardObserver: KeyboardObserver

    private var lastKeyboardFrame: KeyboardObserver.KeyboardFrame? = nil

    private var lastLaidOutSize: CGSize?

    let feedbackGenerator = UINotificationFeedbackGenerator()

    /// Creates a new presentation view controller with the provided style provider.
    ///
    public init(styleProvider: ToastContainerPresentationStyleProvider) {
        self.styleProvider = styleProvider

        keyboardObserver = KeyboardObserver.shared

        super.init(nibName: nil, bundle: nil)

        keyboardObserver.add(delegate: self)

        presentationContextWantsPreferredContentSize = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Update the list of toasts being presented.
    ///
    /// New toasts will begin their enter transition, removed toasts with begin their outgoing transition, and changed
    /// toasts will be updated.
    ///
    public func update(
        toasts: [PresentableToast],
        safeAreaAnchors: [ToastSafeAreaAnchor]
    ) {
        if
            presentations.isEmpty,
            toasts.isEmpty == false
        {
            delegate?.toastPresentationViewControllerDidChange(hasVisiblePresentations: true)
        }

        update(safeAreaAnchors: safeAreaAnchors)
        update(toasts: toasts)
    }

    private func update(toasts: [PresentableToast]) {
        var exitingPresentations = presentations

        var newPresentations: [Presentation] = []

        for toast in toasts {
            if let index = exitingPresentations.index(of: toast.viewController) {
                let presentation = exitingPresentations.remove(at: index)
                presentation.style = toast.presentationStyle

                // If a presentation is in the process of exiting but was re-added we'll want to return it to the
                // presented state.
                if presentation.state.isExiting {
                    presentation.state = .presented
                }

                newPresentations.append(presentation)
            } else {
                let presentation = makePresentation(for: toast)

                newPresentations.append(presentation)
            }
        }

        for presentation in exitingPresentations {
            // If a presentation was not in the exiting state we'll want to queue it for an exit transition.
            if presentation.state.isExiting == false {
                presentation.state = .pendingExit
            }
        }

        presentations = (newPresentations + exitingPresentations)
            .sorted { $0.creationTime < $1.creationTime }

        updatePresentations()
    }

    private func update(safeAreaAnchors: [ToastSafeAreaAnchor]) {
        let view = presentationView
        var insets: UIEdgeInsets = .zero

        for anchor in safeAreaAnchors {
            guard
                anchor.edgeInsets.hasLimits,
                let coordinateSpace = anchor.coordinateSpace
            else { continue }

            let frame = view.convert(coordinateSpace.bounds, from: coordinateSpace)

            if let top = anchor.edgeInsets.top {
                insets.top = max(insets.top, frame.minY + top)
            }

            if let bottom = anchor.edgeInsets.bottom {
                let coordinateSpaceOffset = view.bounds.maxY - frame.maxY
                insets.bottom = max(insets.bottom, coordinateSpaceOffset + bottom)
            }

            if let left = anchor.edgeInsets.left {
                insets.left = max(insets.left, frame.minX + left)
            }

            if let right = anchor.edgeInsets.right {
                let coordinateSpaceOffset = view.bounds.maxX - frame.maxX
                insets.right = max(insets.right, coordinateSpaceOffset + right)
            }
        }

        safeAreaAnchorInsets = insets
    }

    public override func loadView() {
        view = ModalPresentationPassthroughView(
            frame: UIScreen.main.bounds,
            ancestorView: { [weak self] in
                self?.ancestorPresentationView
            }
        )

        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        applyEnvironmentIfNeeded()
    }

    public func apply(environment: ViewEnvironment) {
        let previousStyle = style
        let newStyle = styleProvider.style(for: environment)
        style = newStyle

        guard let previousStyle else {
            updatePresentations()
            return
        }

        if previousStyle.isEqual(to: newStyle) {
            return
        }

        updatePresentations()
    }

    public func customize(environment: inout ViewEnvironment) {}

    private func updatePresentations() {
        guard
            presentations.isEmpty == false,
            isViewLoaded,
            let style
        else { return }

        // On the first pass we'll add child views and "preheat" them by laying them out in the entire available space
        // first. This preheat will allow preferredContentSize to report the appropriate value.
        // We also recompute the auto-dismiss timer in case the delay has changed since the last update.

        for presentation in presentations {
            presentation.autoDismissTimer?.invalidate()
            presentation.autoDismissTimer = nil

            guard !presentation.state.isExiting else {
                continue
            }

            let child = presentation.viewController

            if case .pending = presentation.state {
                addChild(child)
                view.addSubview(presentation.containerView)
                child.didMove(toParent: self)
            }

            switch presentation.state {
            case .transitioningSize,
                 .interactiveInverse,
                 .interactiveDismiss:
                break

            case .exiting,
                 .presented,
                 .pending,
                 .pendingExit,
                 .entering,
                 .updating:
                let preheatContext = makePreheatContext()
                let preheatValues = style.preheatValues(for: preheatContext)
                child.view.frame.size = preheatValues.size
                child.view.layoutIfNeeded()
            }
        }

        // The first pass at computing transition state is done over the entire set of presentations, including those
        // that may be transitioning out. This allows the exit transition style resolution to compute the destination
        // of each removed toast based on its original position.

        do {
            let displayContext = makeDisplayContext(presentations: presentations)
            let displayValues = style.displayValues(for: displayContext)

            for (index, presentation) in presentations.enumerated() {
                switch presentation.state {
                case .pendingExit:
                    view.sendSubviewToBack(presentation.containerView)

                    let presentedValues = displayValues.presentedValues[index]
                    let transitionContext = makeTransitionContext(presentedFrame: presentedValues.frame)
                    let exitValues = style.exitTransitionValues(for: transitionContext)

                    transitionOut(
                        presentation: presentation,
                        exitValues: exitValues,
                        presentedValues: presentedValues
                    )

                case .pending,
                     .entering,
                     .updating,
                     .presented,
                     .exiting,
                     .transitioningSize,
                     .interactiveDismiss,
                     .interactiveInverse:
                    break
                }
            }
        }

        // Perform updates to presentations that layout as if any exiting presentations are not present so they animate
        // to their new location.

        do {
            let presentationsOmittingExiting = presentations.filter { !$0.state.isExiting }

            let displayContext = makeDisplayContext(presentations: presentationsOmittingExiting)
            let displayValues = style.displayValues(for: displayContext)

            for (index, presentation) in presentationsOmittingExiting.enumerated() {
                switch presentation.state {
                case .pending:
                    transitionIn(
                        presentation: presentation,
                        presentedValues: displayValues.presentedValues[index],
                        style: style
                    )

                case .presented:
                    transitionUpdate(
                        presentation: presentation,
                        presentedValues: displayValues.presentedValues[index]
                    )

                case .transitioningSize:
                    layout(
                        presentation: presentation,
                        transitionValues: displayValues.presentedValues[index]
                    )


                case .updating(let animator):
                    updateTransitionUpdate(
                        presentation: presentation,
                        animator: animator,
                        presentedValues: displayValues.presentedValues[index]
                    )

                case .entering(let animator):
                    updateTransitionIn(
                        presentation: presentation,
                        animator: animator,
                        presentedValues: displayValues.presentedValues[index],
                        style: style
                    )

                case .pendingExit,
                     .exiting,
                     .interactiveDismiss,
                     .interactiveInverse:
                    break
                }
            }
        }
    }

    private func makePresentation(for toast: PresentableToast) -> Presentation {
        // If the view isn't loaded, no need to transition in.
        let transitionState: TransitionState = isViewLoaded ? .pending : .presented

        let presentation = Presentation(
            viewController: toast.viewController,
            style: toast.presentationStyle,
            state: transitionState,
            accessibilityAnnouncement: toast.accessibilityAnnouncement
        )

        presentation.panGesture.addTarget(self, action: #selector(handlePan))

        return presentation
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        KeyboardObserver.logKeyboardSetupWarningIfNeeded()

        // Our views size can actually change without a call to viewWillTransitionToSize so we need to layout our
        // presentations if our views size changes.
        if lastLaidOutSize != view.bounds.size {
            lastLaidOutSize = view.bounds.size

            prepareForSizeTransition()
            updatePresentations()
            cleanupAfterSizeTransition()
        }
    }

    public override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)

        // Set this so we don't lay out again in viewDidLayoutSubviews.
        lastLaidOutSize = size

        prepareForSizeTransition()

        coordinator.animate(alongsideTransition: { _ in
            self.updatePresentations()
        }, completion: { _ in
            self.cleanupAfterSizeTransition()
        })
    }

    private func prepareForSizeTransition() {
        for presentation in presentations where
            presentation.state.isExiting == false
        {
            presentation.panGesture.state = .cancelled
            presentation.state = .transitioningSize
        }
    }

    private func cleanupAfterSizeTransition() {
        for presentation in presentations where
            presentation.state.isExiting == false
        {
            presentation.state = .presented

            let behaviorContext = makeBehaviorContext()
            let behaviorPreferences = presentation.style.behaviorPreferences(for: behaviorContext)
            configureTimer(
                presentation: presentation,
                behaviorPreferences: behaviorPreferences
            )
        }
    }
}

extension ToastPresentationViewController: KeyboardObserverDelegate {

    func keyboardFrameWillChange(
        for observer: KeyboardObserver,
        animationDuration: Double,
        animationCurve: UIView.AnimationCurve
    ) {
        guard let keyboardFrame = keyboardObserver.currentFrame(in: presentationView) else {
            return
        }

        guard lastKeyboardFrame != keyboardFrame else {
            return
        }

        lastKeyboardFrame = keyboardFrame

        prepareForSizeTransition()

        let animator = UIViewPropertyAnimator(
            duration: animationDuration,
            curve: animationCurve
        ) {
            self.updatePresentations()
        }

        animator.addCompletion { _ in
            self.cleanupAfterSizeTransition()
        }

        animator.startAnimation()
    }
}

extension [ToastPresentationViewController.Presentation] {

    func index(of viewController: UIViewController) -> Int? {
        firstIndex(where: { $0.viewController == viewController })
    }

    func presentation(for viewController: UIViewController) -> Element? {
        first(where: { $0.viewController == viewController })
    }

    func presentation(for gesture: UIPanGestureRecognizer) -> (Int, Element)? {
        enumerated().first(where: { $1.panGesture == gesture })
    }
}
