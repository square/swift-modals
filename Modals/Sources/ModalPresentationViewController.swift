import UIKit

/// This view controller is capable of presenting the modals in a `ModalList`.
///
/// Generally you should not need to use this view controller directly. Instead, use
/// `ModalHostContainerViewController` to wrap your root view controller.
///
/// If you need to add `ModalHost` conformance to your own view controller, you can embed this view
/// controller to handle the presentation.
///
/// ## See Also:
/// - [ModalHostContainerViewController](x-source-tag://ModalHostContainerViewController)
@objc(MDLModalPresentationViewController)
public final class ModalPresentationViewController: UIViewController {
    /// The view controller of the topmost modal, or nil if no modal is being presented. This is the
    /// view controller that contextual view controller decisions (like status bar style and
    /// supported orientations) should be forwarded to.
    public var topmostViewController: UIViewController? {
        topmostPresentation?.viewController
    }

    /// True if this has any modals that are currently being presented.
    public var hasModals: Bool { !presentations(includeExiting: false).isEmpty }

    /// An array of the view controllers currently being presented as modals.
    public var presentedViewControllers: [UIViewController] {
        presentations(includeExiting: false).map(\.viewController)
    }

    /// Use this property to assign an ancestor `ModalPresentationViewController` view that we should use to determine
    /// the frame of our presentations.
    @_spi(ModalsImplementation)
    public weak var ancestorPresentationView: UIView? {
        didSet {
            guard ancestorPresentationView != oldValue else {
                return
            }

            for presentation in allPresentations {
                presentation.containerViewController.presentationView = ancestorPresentationView
            }
        }
    }

    var topmostPresentation: Presentation? {
        presentations(includeExiting: false).last
    }

    /// The view to use for laying out presentations - either `ancestorPresentationView` if it exists, or our own view.
    private var presentationView: UIView {
        ancestorPresentationView ?? view
    }

    private var visibleViewController: UIViewController {
        topmostViewController ?? content
    }

    var logger = ModalsLogging.logger

    /// The frame to provide to presentation contexts. This may be our bounds, or our ancestor presentations bounds
    /// converted to our coordinate space.
    private var containerFrame: CGRect {
        if let ancestorPresentationView {
            ancestorPresentationView.convert(ancestorPresentationView.bounds, to: view)
        } else {
            view.bounds
        }
    }

    /// Maintains the storage for all focus restoration objects.
    private var focusRestorationStorage = FocusRestorationStorage()

    private var allPresentations: [Presentation] = []
    /// The last size for which we performed a layout on our presentations.
    private var lastLaidOutSize: CGSize?
    private var isTrackingScrollViewDismiss = false
    private let scrollViewFinder = TrackedScrollViewFinder()
    private let panGestureRecognizer = UIPanGestureRecognizer()
    private let tapGestureRecognizer = UITapGestureRecognizer()
    private let content: UIViewController
    private var visibility: Visibility = .disappeared
    private var keyboardFrame: CGRect?
    private var focusableLayers: [FocusableLayer]
    private var accessibilityLayers: [AccessibilityLayer]
    private var accessibilityScreenChangedTimer: Timer? = nil

    // MARK: - Lifecycle


    public init(content: UIViewController) {
        self.content = content

        focusableLayers = [.init(content: content)]
        accessibilityLayers = [.init(viewController: content)]

        super.init(nibName: nil, bundle: nil)

        KeyboardObserver.shared.add(delegate: self)

        addChild(content)
        content.didMove(toParent: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = ModalPresentationPassthroughView(
            frame: content.view.frame,
            ancestorView: { [weak self] in
                self?.ancestorPresentationView
            }
        )

        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        content.view.frame = view.bounds
        view.addSubview(content.view)

        for presentation in allPresentations {
            addChild(presentation.containerViewController)
            view.addSubview(presentation.containerView)
            presentation.containerViewController.didMove(toParent: self)
            updateDecorationViews(for: presentation)
        }

        updateFirstResponderAndAccessibilityFocus()

        view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.addTarget(self, action: #selector(handlePan))
        tapGestureRecognizer.addTarget(self, action: #selector(handleTap))

        updatePreferredContentSize()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visibility = .appearing
        content.beginAppearanceTransition(true, animated: animated)
        for presentation in allPresentations {
            presentation.containerVisibility = visibility
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visibility = .appeared
        content.endAppearanceTransition()
        for presentation in allPresentations {
            presentation.containerVisibility = visibility
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        visibility = .disappearing
        content.beginAppearanceTransition(false, animated: animated)
        for presentation in allPresentations {
            presentation.containerVisibility = visibility
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        visibility = .disappeared
        content.endAppearanceTransition()
        for presentation in allPresentations {
            presentation.containerVisibility = visibility
        }
    }

    // MARK: - Modal Presentation

    private func presentations(includeExiting: Bool) -> [Presentation] {
        if includeExiting {
            allPresentations
        } else {
            allPresentations.filter { presentation in
                switch presentation.transitionState {
                case .pendingExit,
                     .exiting,
                     .pendingRemoval:
                    false
                case .pending,
                     .entering,
                     .presented,
                     .transitioningSize,
                     .interactiveDismiss,
                     .interactiveInverse,
                     .adaptingToKeyboard:
                    true
                }
            }
        }
    }

    private func newPresentation(for modal: PresentableModal) -> Presentation {

        // If the view isn't loaded, no need to transition in.
        let transitionState: TransitionState = isViewLoaded ? .pending : .presented

        let style = modal.presentationStyle
        let behaviorPreferences = style.behaviorPreferences(for: behaviorContext())

        var accessibilityDismissal = Presentation.AccessibilityDismissal()

        // If the modal has an overlay tap dismissal, we'll allow accessibility
        // dismissal as well.
        if behaviorPreferences.overlayTap.onDismiss != nil {
            accessibilityDismissal.activate = { [weak self] in
                self?.accessibilityPerformEscape() ?? false
            }
        }

        return Presentation(
            viewController: modal.viewController,
            onDidPresent: modal.onDidPresent,
            style: style,
            containerVisibility: visibility,
            behaviorPreferences: behaviorPreferences,
            transitionState: transitionState,
            presentationView: presentationView,
            accessibilityDismissal: accessibilityDismissal
        )
    }

    /// Update the list of modals being presented.
    ///
    /// New modals will begin their enter transition, removed modals with begin their outgoing
    /// transition, and changed modals will be updated.
    public func update(modals: [PresentableModal]) {
        let oldTopPresentation = topmostPresentation

        let oldStatusBarAppearanceSource = topmostViewController(
            passingContainmentPreference: \.providesStatusBarAppearance
        )
        let oldHomeIndicatorHiddenSource = topmostViewController(
            passingContainmentPreference: \.providesHomeIndicatorAutoHidden
        )
        let oldScreenEdgesDeferringSystemGesturesSource = topmostViewController(
            passingContainmentPreference: \.providesScreenEdgesDeferringSystemGestures
        )
        let oldSupportedInterfaceOrientationsSource = topmostViewController(
            passingContainmentPreference: \.providesSupportedInterfaceOrientations
        )

        // Will become a list of presentations that need to be transitioned out
        let oldPresentations = allPresentations
        // Will contain the new set of presented modals
        var newPresentations: [Presentation] = []

        for modal in modals {
            if let index = oldPresentations.index(of: modal.viewController) {
                let oldPresentation = oldPresentations[index]
                let style = modal.presentationStyle

                oldPresentation.style = style
                oldPresentation.behaviorPreferences = style.behaviorPreferences(for: behaviorContext())

                newPresentations.append(oldPresentation)
            } else {
                let presentation = newPresentation(for: modal)
                newPresentations.append(presentation)
            }
        }

        // Insert old presentations that need to be transitioned out
        for (index, presentation) in oldPresentations.enumerated() where !newPresentations.contains(where: {
            $0.viewController == presentation.viewController
        }) {
            // If we're not already exiting, mark it as pending
            if case .exiting = presentation.transitionState {
                // Do nothing
            } else {
                presentation.transitionState = .pendingExit
            }

            if index == 0 {
                // If we have no predecessor, stay at the back of the list
                newPresentations.insert(presentation, at: 0)
            } else if let newPredecessorIndex = newPresentations.firstIndex(where: {
                $0.viewController == oldPresentations[index - 1].viewController
            }) {
                // If we can find our old predecessor in the new list, place ourselves in front of it
                newPresentations.insert(presentation, at: newPredecessorIndex + 1)
            } else {
                // This should never happen, even if our predecessor is going to transition out it should have been
                // inserted into the list of new presentations.
                fatalError("Unexpectedly failed to find predecessor presentation.")
            }
        }

        // Update our state to reflect the modals post-update.
        allPresentations = newPresentations

        updatePresentations(oldTopPresentation: oldTopPresentation)

        if oldStatusBarAppearanceSource != topmostViewController(
            passingContainmentPreference: \.providesStatusBarAppearance
        ) {
            setNeedsStatusBarAppearanceUpdate()
        }

        if oldHomeIndicatorHiddenSource != topmostViewController(
            passingContainmentPreference: \.providesHomeIndicatorAutoHidden
        ) {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }

        if oldScreenEdgesDeferringSystemGesturesSource != topmostViewController(
            passingContainmentPreference: \.providesScreenEdgesDeferringSystemGestures
        ) {
            setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        }

        if oldSupportedInterfaceOrientationsSource != topmostViewController(
            passingContainmentPreference: \.providesSupportedInterfaceOrientations
        ) {
            setNeedsUpdateOfSupportedInterfaceOrientationsAndRotateIfNeeded()
        }

        updateTopPresentation()
    }

    private func updatePresentations(oldTopPresentation: Presentation?) {

        guard isViewLoaded else { return }

        updateFirstResponderAndAccessibilityFocus()

        // Only re-arrange views if they don't already match the hierarchy.
        // (We dropFirst because our first subview is `content.view`.)
        let viewsNeedSorting = allPresentations.map(\.containerView) != Array(view.subviews.dropFirst())

        for presentation in allPresentations {
            // Add any pending presentation views
            if case .pending = presentation.transitionState {

                let fromViewController = oldTopPresentation?.viewController ?? content

                logger.log(
                    level: .info,
                    "Modal presentation will transition",
                    event: ModalPresentationWillTransitionLogEvent(
                        presenterViewController: self,
                        fromViewController: fromViewController,
                        toViewController: presentation.viewController,
                        transitionState: .entering,
                        animated: true
                    )
                )

                addChild(presentation.containerViewController)
                view.addSubview(presentation.containerView)
                presentation.containerViewController.didMove(toParent: self)
            } else if viewsNeedSorting {
                view.bringSubviewToFront(presentation.containerView)
            }

            updateDecorationViews(for: presentation)

            // Present new modals

            switch presentation.transitionState {
            case .pending:
                setUpTransitionIn(presentation: presentation)
                transitionIn(presentation: presentation)

            case .pendingExit:
                setUpTransitionOut(presentation: presentation, isInteractive: false)
                transitionOut(presentation: presentation, shouldRemove: true)

            case .pendingRemoval:
                remove(presentation: presentation)

            case .entering,
                 .exiting,
                 .interactiveDismiss,
                 .interactiveInverse,
                 .presented,
                 .transitioningSize,
                 .adaptingToKeyboard:
                break
            }
        }
    }

    private func updateFirstResponderAndAccessibilityFocus() {

        guard isViewLoaded else {
            return
        }

        updateFirstResponder()
        updateAccessibilityViewIsModal()
    }

    private func updateFirstResponder() {

        let oldLayers = focusableLayers

        focusableLayers = [.init(content: content)] + presentations(includeExiting: false)
            .filter {
                // We only treat presentations as focusable layers if:
                // 1) They resign the existing first responder on presentation, or
                // 2) They have a recorded first responder. This could happen
                // despite the presentation not resigning the existing first
                // responder when presented. e.g. a blade that had a field focused
                // after presentation.
                $0.behaviorPreferences.resignsExistingFirstResponder ||
                    focusRestorationStorage.focusRestoration(for: $0.viewController).hasRecordedFirstResponder
            }
            .map {
                FocusableLayer(content: $0.viewController)
            }

        /// Note: We can use `!` here, because our base `content` is always included in the array; it can never be empty.

        let oldTopLayer = oldLayers.last!
        let topLayer = focusableLayers.last!

        /// If the layering didn't change, then nothing changed, we can bail early.

        guard oldTopLayer != topLayer else {
            return
        }

        let removed = oldLayers.filter { old in
            focusableLayers.contains { $0 == old } == false
        }

        /// The old top layer is still in the modal list, so we want to record the first responder from it.

        if focusableLayers.contains(oldTopLayer) {
            focusRestorationStorage.focusRestoration(for: oldTopLayer.content).recordFirstResponder { firstResponder in
                firstResponder.resignFirstResponder()
            }
        }

        /// We can now restore the first responder to the new top layer.

        focusRestorationStorage.focusRestoration(for: topLayer.content).restoreFirstResponder()

        /// In case these view controllers will be retained longer term, clear out any focus information.
        /// Note: This will also clear the focused a11y element.

        for remove in removed {
            focusRestorationStorage.focusRestoration(for: remove.content).clearRecordedResponders()
        }
    }

    private func updateAccessibilityViewIsModal() {

        let oldLayers = accessibilityLayers

        /// All layers in the modal presentation, including the base content view.

        accessibilityLayers = [.init(viewController: content)] + presentations(includeExiting: false)
            .map {
                AccessibilityLayer(
                    viewController: $0.viewController,
                    containerView: $0.containerView
                )
            }

        /// Note: We can use ! here, because our base `content` is always included in the array; it can never be empty.

        let oldTopLayer = oldLayers.last!
        let topLayer = accessibilityLayers.last!

        /// If the layering didn't change, then nothing changed, we can bail early.

        guard oldTopLayer != topLayer else {
            return
        }

        /// The old top layer is still in the modal list, so we want to record the first responder from it.

        if accessibilityLayers.contains(oldTopLayer) {
            focusRestorationStorage.focusRestoration(for: oldTopLayer.viewController).recordFocusedAccessibilityElement()
        }

        /// Note: We don't restore a11y here, it's done once the
        /// presentation or dismissal animation is completed after a short delay.
        ///
        /// See `postAccessibilityScreenChangedNotification`.

        /// Now we can update our `accessibilityViewIsModal` status.
        /// This ensures that VoiceOver users only see the top-most modal layer.

        let views = allPresentations.map(\.containerView)

        views.last?.accessibilityViewIsModal = true

        for view in views.dropLast() {
            view.accessibilityViewIsModal = false
        }
    }

    private func postAccessibilityScreenChangedNotification() {

        if let timer = accessibilityScreenChangedTimer {

            /// If we animate multiple modals in or out at the same time or in quick succession,
            /// we cancel the last timer and enqueue another one, only posting the screen
            /// changed notification when all modal transitions have settled.

            timer.invalidate()

            accessibilityScreenChangedTimer = nil
        }

        /// **Note**: We provide a short delay to allow the layout and accessibility
        /// system to "settle", otherwise selection can be non-deterministic.

        accessibilityScreenChangedTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            guard let self else { return }

            func focusedElement() -> NSObject? {
                guard let top = accessibilityLayers.last else {
                    return nil
                }

                let focus = focusRestorationStorage.focusRestoration(for: top.viewController)

                defer {
                    focus.focusedAccessibilityElement = nil
                }

                return focus.focusedAccessibilityElement ?? top.viewController.view
            }

            UIAccessibility.post(
                notification: .screenChanged,
                argument: focusedElement()
            )
        }
    }

    private func updateTopPresentation() {
        if let topPresentation = topmostPresentation {

            let behavior = topPresentation.behaviorPreferences

            switch behavior.interactiveDismiss {
            case .swipeDown:
                panGestureRecognizer.isEnabled = true
            case .disabled:
                panGestureRecognizer.isEnabled = false
            }

            switch behavior.overlayTap {
            case .passThrough:
                topPresentation.containerView.passThroughOverlayTouches = .all
            case .disabled, .tap, .dismiss:
                topPresentation.containerView.passThroughOverlayTouches = .none(allowing: behavior.sourceView)
            }

            topPresentation.containerView.passThroughContentTouches = behavior.passThroughContentTouches
            topPresentation.overlayView.addGestureRecognizer(tapGestureRecognizer)
            scrollViewFinder.viewController = topPresentation.viewController
            updateTrackedScrollView(for: topPresentation)
        } else {
            panGestureRecognizer.isEnabled = false
            scrollViewFinder.viewController = nil
        }
    }

    private func updateDecorationViews(for presentation: Presentation) {
        let context = presentationContext(for: presentation, isInteractive: false)
        let displayValues = presentation.style.displayValues(for: context)
        let decorations = displayValues.decorations

        // Add or replace decorations as necessary.
        for (index, decoration) in decorations.enumerated() {
            let shouldInsert =
                // This is a net new decoration, add it.
                index >= presentation.decorationViews.count
                // This decoration should replace one at this position previously.
                || !decoration.canUpdate(presentation.decorationViews[index])

            if shouldInsert {
                let view = decoration.build()
                presentation.containerView.addSubview(view)
                presentation.decorationViews.insert(view, at: index)
            }
        }

        // Remove excess decorations from previous presentations.
        while decorations.count < presentation.decorationViews.count {
            presentation.decorationViews
                .removeLast()
                .removeFromSuperview()
        }
    }

    private func layoutDecorations(
        for presentation: Presentation,
        opacity: CGFloat,
        isInteractive: Bool
    ) {
        let context = presentationContext(for: presentation, isInteractive: isInteractive)
        let displayValues = presentation.style.displayValues(for: context)
        let decorations = displayValues.decorations

        for (view, decoration) in zip(presentation.decorationViews, decorations) {
            view.alpha = opacity
            decoration.update(view)
            view.frame = presentation.containerView.convert(
                decoration.frame,
                from: presentation.clippingView
            )
        }
    }

    private func updateTrackedScrollView(for presentation: Presentation) {
        scrollViewFinder.updateTrackedScrollView(ifChanged: { oldScrollView, newScrollView in
            oldScrollView?.panGestureRecognizer.removeTarget(self, action: #selector(handleScroll))
        })

        // Use the `scrollView` property to update our listener, since the callback above
        // is only called if the `scrollView` changed.

        let behavior = presentation.style.behaviorPreferences(for: behaviorContext())
        switch behavior.interactiveDismiss {
        case .swipeDown:
            scrollViewFinder.scrollView?.panGestureRecognizer
                .addTarget(self, action: #selector(handleScroll))
        case .disabled:
            scrollViewFinder.scrollView?.panGestureRecognizer
                .removeTarget(self, action: #selector(handleScroll))
        }
    }

    private func setUpTransitionOut(presentation: Presentation, isInteractive: Bool) {
        let context = presentationContext(for: presentation, isInteractive: isInteractive)
        let exitValues = presentation.style.exitTransitionValues(for: context)
        let displayValues = presentation.style.displayValues(for: context)

        UIView.performWithoutAnimation {
            exitValues.roundedCorners.apply(toView: presentation.clippingView)
            presentation.shadowView.apply(
                shadow: displayValues.shadow,
                corners: exitValues.roundedCorners
            )
        }
    }

    private func transitionOut(presentation: Presentation, shouldRemove: Bool, completion: (() -> Void)? = nil) {
        let presentations = allPresentations
            .filter { modal in
                if case .exiting = modal.transitionState {
                    return false
                }
                return true
            }

        let toViewController = presentations
            .dropLast()
            .last?
            .viewController ?? content

        logger.log(
            level: .info,
            "Modal presentation will transition",
            event: ModalPresentationWillTransitionLogEvent(
                presenterViewController: self,
                fromViewController: presentation.viewController,
                toViewController: toViewController,
                transitionState: .exiting,
                animated: true
            )
        )

        presentation.containerViewController.willMove(toParent: nil)

        let standardExitTransitionValues: ModalTransitionValues = {
            let context = presentationContext(for: presentation, isInteractive: false)
            return presentation.style.exitTransitionValues(for: context)
        }()

        // From: https://developer.apple.com/documentation/uikit/uispringtimingparameters/1649909-initialvelocity?language=swift
        let currentPosition = presentation.presentationFrame
        let finalPosition = standardExitTransitionValues.frame
        let yDistance = finalPosition.origin.y - currentPosition.origin.y
        let gestureVelocity = panGestureRecognizer
            .velocity(in: presentation.containerView)
        let isInteractive = gestureVelocity != .zero && yDistance != 0

        let context = presentationContext(for: presentation, isInteractive: isInteractive)

        let exitValues = presentation.style.exitTransitionValues(for: context)

        func outgoingAnimator() -> UIViewPropertyAnimator {

            var velocity = CGVector.zero

            if isInteractive {
                // Set the dx value to our y velocity, since dx is used for 1d values
                // and we want the entire animation sped up based on the y velocity.
                velocity.dx = gestureVelocity.y / yDistance
                velocity.dy = gestureVelocity.y / yDistance

                return UIViewPropertyAnimator(animation: .spring(initialVelocity: velocity))
            } else {
                return UIViewPropertyAnimator(animation: exitValues.animation)
            }
        }

        let animator = outgoingAnimator()

        animator.addAnimations {
            presentation.presentationView.set(
                frame: exitValues.frame,
                transform: exitValues.transform
            )
            presentation.presentationView.alpha = exitValues.alpha
            presentation.overlayView.alpha = exitValues.overlayOpacity
            presentation.containerView.layoutIfNeeded()

            self.layoutDecorations(
                for: presentation,
                opacity: exitValues.decorationOpacity,
                isInteractive: isInteractive
            )
        }

        animator.addCompletion { [weak self] _ in
            guard let self else { return }

            if shouldRemove {
                remove(presentation: presentation)
            } else {
                presentation.transitionState = .pendingRemoval
            }

            postAccessibilityScreenChangedNotification()
            completion?()
        }

        presentation.transitionState = .exiting(animator)
        animator.startAnimation()
    }

    private func remove(presentation: Presentation) {

        // Presentations must be in the terminal state before being removed, to ensure lifecycle
        // methods have been called. If the presentation is already in this state, this will have no
        // effect.
        presentation.transitionState = .pendingRemoval

        presentation.containerView.removeFromSuperview()
        presentation.containerViewController.removeFromParent()
        presentation.overlayView.removeFromSuperview()
        presentation.decorationViews.forEach { $0.removeFromSuperview() }

        allPresentations.removeAll { $0.viewController === presentation.viewController }
    }

    private func setUpTransitionIn(presentation: Presentation) {
        let behaviorPreferences = presentation.style.behaviorPreferences(for: behaviorContext())

        UIView.performWithoutAnimation {
            // Perform a "preheat" layout for things like preferredContentSize and safe areas so our
            // ModalPresentationContext is correct.
            //
            // During the first layout, the presented VC will likely have a preferred content size of
            // zero, which we treat as "no preferred content size." The ModalPresentationContext will
            // have a nil preferred content size, forcing the modal style to offer a default. We perform
            // our first layout, allowing the presented VC to actually perform a layout, taking into
            // account the safe area, and possibly setting its preferred content size. The second layout
            // can now be done with correct layout values, ensuring frames are correct if they depend
            // on the preferred content size or the safe area insets.
            //
            // Concretely, the double layout fixes an issue with the popover style being presented from
            // a container with left or right safe area insets.
            if behaviorPreferences.usesPreferredContentSize {
                layout(
                    presentation: presentation,
                    isInteractive: false
                )
            }

            layout(
                presentation: presentation,
                isInteractive: false
            )
        }

        let context = presentationContext(for: presentation, isInteractive: false)
        let enterValues = presentation.style.enterTransitionValues(for: context)
        let displayValues = presentation.style.displayValues(for: context)

        UIView.performWithoutAnimation {
            presentation.presentationView.set(
                frame: enterValues.frame,
                transform: enterValues.transform
            )
            presentation.presentationView.alpha = enterValues.alpha
            presentation.overlayView.alpha = enterValues.overlayOpacity
            presentation.overlayView.backgroundColor = displayValues.overlayColor
            presentation.containerView.frame = containerFrame

            enterValues.roundedCorners.apply(toView: presentation.clippingView)
            presentation.shadowView.apply(
                shadow: displayValues.shadow,
                corners: enterValues.roundedCorners
            )

            layoutDecorations(
                for: presentation,
                opacity: enterValues.decorationOpacity,
                isInteractive: false
            )
        }

    }

    func transitionIn(presentation: Presentation) {
        let context = presentationContext(for: presentation, isInteractive: false)
        let displayValues = presentation.style.displayValues(for: context)
        let enterValues = presentation.style.enterTransitionValues(for: context)

        let animator = UIViewPropertyAnimator(animation: enterValues.animation)

        animator.addAnimations {
            presentation.presentationView.set(
                frame: displayValues.frame,
                transform: .identity
            )
            presentation.presentationView.alpha = displayValues.alpha
            presentation.overlayView.alpha = displayValues.overlayOpacity
            presentation.containerView.layoutIfNeeded()

            self.layoutDecorations(
                for: presentation,
                opacity: 1,
                isInteractive: false
            )
        }

        animator.addCompletion { [weak self] _ in
            guard let self else { return }

            // Apply display values again in case they changed during entrance, which might be due to rotation, or safe
            // area insets updating during the transition.
            let context = presentationContext(for: presentation, isInteractive: false)
            let oldDisplayValues = displayValues
            let displayValues = presentation.style.displayValues(for: context)

            if presentation.behaviorPreferences.adjustsForKeyboard,
               displayValues.frame != oldDisplayValues.frame
            {
                // Our frame has changed during the transition in, likely due
                // to the keyboard appearing/disappearing. We transition to
                // `.adaptingToKeyboard` immediately, begin to animate the frame change,
                // and queue a transition to `.presented` to occur when the animation completes.
                let animator = UIViewPropertyAnimator(animation: enterValues.animation)

                animator.addAnimations {
                    presentation.presentationView.set(
                        frame: displayValues.frame,
                        transform: .identity
                    )
                }

                animator.addCompletion { _ in
                    presentation.transitionState = .presented
                }

                presentation.transitionState = .adaptingToKeyboard(animator)
                animator.startAnimation()
            } else {
                presentation.transitionState = .presented
                presentation.presentationView.set(
                    frame: displayValues.frame,
                    transform: .identity
                )
            }

            displayValues.roundedCorners.apply(toView: presentation.clippingView)
            presentation.shadowView.apply(
                shadow: displayValues.shadow,
                corners: displayValues.roundedCorners
            )
            layoutDecorations(
                for: presentation,
                opacity: 1,
                isInteractive: false
            )

            postAccessibilityScreenChangedNotification()
            presentation.onDidPresent?()
        }

        presentation.transitionState = .entering(animator)
        animator.startAnimation()
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        content.view.frame = view.bounds

        for presentation in allPresentations {
            presentation.containerView.frame = containerFrame
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let topmostPresentation {
            updateTrackedScrollView(for: topmostPresentation)
        }

        // Our views size can actually change without a call to viewWillTransitionToSize
        // so we need to layout our presentations if our views size changes.
        if lastLaidOutSize != view.bounds.size {
            lastLaidOutSize = view.bounds.size

            for presentation in allPresentations {
                layout(
                    presentation: presentation,
                    isInteractive: presentation.transitionState.isInteracting
                )
            }
        } else {
            for presentation in allPresentations
                where presentation.behaviorPreferences.needsLayoutOnPresentationLayout
            {
                layout(
                    presentation: presentation,
                    isInteractive: presentation.transitionState.isInteracting
                )
            }
        }
    }

    public override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)

        // Set this so we don't lay out again in viewDidLayoutSubviews.
        lastLaidOutSize = size

        // Cancel an interaction if it's happening.
        panGestureRecognizer.state = .cancelled

        for presentation in allPresentations {
            // The `transitioningSize` state is used to indicate that a layout is being performed in the coordinator,
            // which needs to handled different than other animated layouts. Since it doesn't use a
            // UIViewPropertyAnimator, performing an animation due to, e.g., preferredContentSizeDidChange, causes very
            // strange animations. If the presentation style uses preferred content size we'll instead do two layout
            // passes - one to "preheat" and one to ensure we're laying out the correct display values during the
            // animation if the preferredContentSize changed.
            //
            // If we're exiting, stay in the exiting state so the outgoing transition values are used.

            switch presentation.transitionState {
            case .exiting,
                 .pendingRemoval:
                break
            case .entering,
                 .pending,
                 .pendingExit,
                 .presented,
                 .interactiveInverse,
                 .interactiveDismiss,
                 .transitioningSize,
                 .adaptingToKeyboard:
                presentation.transitionState = .transitioningSize
            }

            let behaviorPreferences = presentation.style.behaviorPreferences(for: behaviorContext())

            coordinator.animate(alongsideTransition: { _ in
                // We only need a "preheat layout" if the style requires use of the `preferredContentSize`.
                //
                // Note: We set `ignoreKeyboardFrame` to `true` because during the
                // transition the keyboard frame is incorrect. Future keyboard
                // notifications will take care of readjusting, if needed.
                if behaviorPreferences.usesPreferredContentSize {
                    self.layout(
                        presentation: presentation,
                        isInteractive: presentation.transitionState.isInteracting,
                        ignoreKeyboardFrame: true
                    )
                }
                self.layout(
                    presentation: presentation,
                    isInteractive: presentation.transitionState.isInteracting,
                    ignoreKeyboardFrame: true
                )
            }, completion: { _ in
                switch presentation.transitionState {
                case .exiting: break
                default: presentation.transitionState = .presented
                }
            })
        }
    }

    public override func aggregateModals() -> ModalList {
        assertionFailure(
            "ModalPresentationViewController should not participate in modal aggregation"
        )

        return ModalList()
    }

    // MARK: - View Controller Containment Delegation

    public override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        false
    }

    public override var childForStatusBarStyle: UIViewController? {
        topmostViewController(passingContainmentPreference: \.providesStatusBarAppearance)
    }

    public override var childForStatusBarHidden: UIViewController? {
        topmostViewController(passingContainmentPreference: \.providesStatusBarAppearance)
    }

    public override var childForHomeIndicatorAutoHidden: UIViewController? {
        topmostViewController(passingContainmentPreference: \.providesHomeIndicatorAutoHidden)
    }

    public override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        topmostViewController(passingContainmentPreference: \.providesScreenEdgesDeferringSystemGestures)
    }

    public override var childViewControllerForPointerLock: UIViewController? {
        topmostViewController(passingContainmentPreference: \.providesPointerLock)
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        topmostViewController(passingContainmentPreference: \.providesSupportedInterfaceOrientations)
            .supportedInterfaceOrientations
    }

    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        topmostViewController(passingContainmentPreference: \.providesStatusBarAppearance)
            .preferredStatusBarUpdateAnimation
    }

    public override var isModalInPresentation: Bool {
        get {
            super.isModalInPresentation || content.isModalInPresentation
        }
        set {
            super.isModalInPresentation = newValue
        }
    }

    // MARK: - Layout

    public override func preferredContentSizeDidChange(
        forChildContentContainer container: UIContentContainer
    ) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        guard container !== content else {
            updatePreferredContentSize()
            return
        }

        guard
            let containerViewController = container as? ContainerViewController,
            let presentation = presentations(includeExiting: false).presentation(for: containerViewController.content)
        else {
            return
        }

        let behaviorPreferences = presentation.style.behaviorPreferences(for: behaviorContext())
        guard behaviorPreferences.usesPreferredContentSize else {
            return
        }

        func updateLayoutForContentSizeChange() {
            // Only animate our change if we're in the foreground; otherwise, changes due
            // to scene resizing animate, which looks very bad.
            if let activationState = view.window?.windowScene?.activationState,
               activationState != .foregroundActive
            {
                layout(presentation: presentation, isInteractive: false)
            } else {
                let animator = UIViewPropertyAnimator(animation: .spring())

                animator.addAnimations {
                    self.layout(presentation: presentation, isInteractive: false)
                }

                animator.startAnimation()
            }
        }

        func animateContentSizeChangedDuringEntrance(with animator: UIViewPropertyAnimator) {

            let displayValues = presentation.style.displayValues(for: presentationContext(
                for: presentation,
                isInteractive: false
            ))

            logger.debug(
                """
                Modal \(presentation.viewController) \
                Animating content size changed during entrance
                """,
                metadata: ["displayValues.frame": "\(displayValues.frame)"]
            )

            animator.addAnimations {
                presentation.presentationView.set(
                    frame: displayValues.frame,
                    transform: .identity
                )

                self.layoutDecorations(
                    for: presentation,
                    opacity: 1,
                    isInteractive: false
                )
            }
        }

        logger.debug("""
        Modal \(presentation.viewController) \
        in state \(presentation.transitionState) \
        preferredContentSize changed to \(presentation.viewController.preferredContentSize)
        """)

        switch presentation.transitionState {
        case .presented, .pendingExit, .adaptingToKeyboard:
            // If the presentation is presented, immediately update the layout.
            // If the transition is adaptingToKeyboard, this often will be batched with
            // content update that may have affected content size changes, so we'll need to
            // update the layout in some cases.
            updateLayoutForContentSizeChange()

        case .entering(let animator):
            // The reported content size changed during the entrance animation of the modal.
            // Update the running animation to the new frame.
            animateContentSizeChangedDuringEntrance(with: animator)

        case .exiting,
             .pendingRemoval,
             .pending,
             .transitioningSize,
             .interactiveDismiss,
             .interactiveInverse:
            // If the transition is animating off screen or being interacted with, there's no
            // reason to update the preferred content size. If we haven't started the transition,
            // we don't need to do anything - presenting the modal will update it with the current
            // context. In the case of interaction, it'll be updated if we transition back to the
            // presented state.
            break
        }
    }

    private func presentationContext(
        for presentation: Presentation,
        isInteractive: Bool,
        ignoreKeyboardFrame: Bool = false
    ) -> ModalPresentationContext {
        let preferredContentSize: CGSize = {
            let behaviorPreferences = presentation.style.behaviorPreferences(for: behaviorContext())
            if behaviorPreferences.usesPreferredContentSize {
                return presentation.viewController.preferredContentSize
            } else {
                return .zero
            }
        }()

        return ModalPresentationContext(
            containerCoordinateSpace: presentationView,
            containerSafeAreaInsets: presentationView.safeAreaInsets,
            containerKeyboardFrame: ignoreKeyboardFrame ? nil : keyboardFrame,
            preferredContentSize: .init(preferredContentSize),
            currentFrame: presentation.currentFrame,
            scale: view.layer.contentsScale,
            isInteractive: isInteractive
        )
    }

    private func updatePreferredContentSize() {
        let preferredContentSize = content.preferredContentSize

        guard self.preferredContentSize != preferredContentSize else { return }

        self.preferredContentSize = preferredContentSize
    }

    private func behaviorContext() -> ModalBehaviorContext {
        ModalBehaviorContext()
    }

    private func layout(
        presentation: Presentation,
        isInteractive: Bool,
        ignoreKeyboardFrame: Bool = false
    ) {
        let context = presentationContext(
            for: presentation,
            isInteractive: isInteractive,
            ignoreKeyboardFrame: ignoreKeyboardFrame
        )

        func presentedLayout() {
            let displayValues = presentation.style.displayValues(for: context)

            // Since this function can be called animated, we want to ensure that we do not force an animated layout
            // of the modal content if the frame hasn't changed.
            let frameChanged = (displayValues.frame != presentation.presentationView.frame)
            let boundsChanged = (containerFrame != presentation.containerView.frame)
            if frameChanged || boundsChanged {
                presentation.presentationView.set(
                    frame: displayValues.frame,
                    transform: .identity
                )
                presentation.containerView.frame = containerFrame
                presentation.containerView.layoutIfNeeded()
            }

            presentation.presentationView.alpha = displayValues.alpha
            presentation.overlayView.alpha = displayValues.overlayOpacity
            presentation.overlayView.backgroundColor = displayValues.overlayColor

            // Only update rounded corners if we're fully presented to avoid stomping over them
            switch presentation.transitionState {
            case .presented,
                 .transitioningSize,
                 .adaptingToKeyboard,
                 .interactiveDismiss,
                 .interactiveInverse,
                 .pendingExit,
                 .exiting:
                displayValues.roundedCorners.apply(toView: presentation.clippingView)
                presentation.shadowView.apply(
                    shadow: displayValues.shadow,
                    corners: displayValues.roundedCorners
                )
            case .entering,
                 .pending,
                 .pendingRemoval:
                break
            }

            layoutDecorations(for: presentation, opacity: 1, isInteractive: isInteractive)
        }

        func layout(transitionValues: ModalTransitionValues) {
            let displayValues = presentation.style.displayValues(for: context)

            presentation.presentationView.set(
                frame: transitionValues.frame,
                transform: transitionValues.transform
            )
            presentation.presentationView.alpha = transitionValues.alpha
            presentation.containerView.frame = containerFrame
            presentation.overlayView.alpha = transitionValues.overlayOpacity
            presentation.overlayView.backgroundColor = displayValues.overlayColor
            transitionValues.roundedCorners.apply(toView: presentation.clippingView)
            presentation.shadowView.apply(
                shadow: displayValues.shadow,
                corners: transitionValues.roundedCorners
            )

            presentation.containerView.layoutIfNeeded()

            layoutDecorations(
                for: presentation,
                opacity: transitionValues.decorationOpacity,
                isInteractive: isInteractive
            )
        }

        switch presentation.transitionState {
        case .presented,
             .entering,
             .interactiveDismiss,
             .interactiveInverse,
             .pending,
             .pendingExit,
             .transitioningSize,
             .adaptingToKeyboard:
            // If we're presented or entering, updating the layout to the display values is the
            // correct thing to do.
            //
            // If we're pending, we have started a transition and we should do a normal layout
            // to preheat the preferred content size with correct values.
            presentedLayout()
        case .exiting:
            // If the animation is transitioning out, update the layout to the outgoing values.
            let transitionValues = presentation.style.exitTransitionValues(for: context)
            layout(transitionValues: transitionValues)
        case .pendingRemoval:
            break
        }
    }

    private func topmostPresentation(
        passingContainmentPreference: (ModalBehaviorPreferences.ViewControllerContainmentPreferences) -> Bool
    ) -> Presentation? {
        guard let topmostPresentation else {
            return nil
        }

        let behaviorContext = behaviorContext()
        let behaviorPreferences = topmostPresentation.style.behaviorPreferences(for: behaviorContext)
        if passingContainmentPreference(behaviorPreferences.viewControllerContainmentPreferences) {
            return topmostPresentation
        } else {
            return presentations(includeExiting: false).last {
                let behaviorPreferences = $0.style.behaviorPreferences(for: behaviorContext)
                return passingContainmentPreference(behaviorPreferences.viewControllerContainmentPreferences)
            }
        }
    }

    private func topmostViewController(
        passingContainmentPreference: (ModalBehaviorPreferences.ViewControllerContainmentPreferences) -> Bool
    ) -> UIViewController {
        let presentation = topmostPresentation(passingContainmentPreference: passingContainmentPreference)
        return presentation?.viewController ?? content
    }

    // MARK: - Interaction

    /// This method is called when Voice Over is enabled and the escape gesture is performed
    /// (a 2-finger Z shape). When this occurs, we inspect the topmost presentation. If it has
    /// enabled accessibility escape behavior, we call the handler.
    public override func accessibilityPerformEscape() -> Bool {
        guard let topmostPresentation else {
            return false
        }

        let behavior = topmostPresentation.style.behaviorPreferences(for: behaviorContext())

        if let onDismiss = behavior.overlayTap.onDismiss {
            onDismiss()
            return true
        }

        if let onDismiss = behavior.interactiveDismiss.onDismiss {
            onDismiss()
            return true
        }

        return false
    }

    // The dismiss interaction animates towards the outgoing values with a linear scrub.
    // Both handlePan and handleScroll use this function to begin a transition out.
    private func setUpDismissInteraction(for presentation: Presentation, fractionComplete: CGFloat) {
        if case .presented = presentation.transitionState {
            setUpTransitionOut(presentation: presentation, isInteractive: true)
        }

        let context = presentationContext(for: presentation, isInteractive: true)
        let exitValues = presentation.style.exitTransitionValues(for: context)

        let animator = UIViewPropertyAnimator(animation: .spring())

        animator.addAnimations {
            presentation.presentationView.set(
                frame: exitValues.frame,
                transform: exitValues.transform
            )
            presentation.presentationView.alpha = exitValues.alpha
            presentation.overlayView.alpha = exitValues.overlayOpacity

            self.layoutDecorations(
                for: presentation,
                opacity: exitValues.decorationOpacity,
                isInteractive: true
            )
        }

        // Ensure we update our state *before* updating the animation, since starting the
        // animation will cause things to lay out
        presentation.transitionState = .interactiveDismiss(animator)
        animator.fractionComplete = fractionComplete
    }

    private func projectShouldDismiss(
        for presentation: Presentation,
        with velocity: CGPoint,
        destinationFrame: CGRect
    ) -> Bool {
        let currentFrame = presentation.presentationFrame
        let projectedFrame = Dynamics.projectedFrame(from: currentFrame, initialVelocity: velocity)
        return projectedFrame.origin.y >= destinationFrame.origin.y
    }

    @objc private func handleTap(gesture: UITapGestureRecognizer) {
        guard let presentation = topmostPresentation else {
            return
        }

        let behaviorPreferences = presentation.style
            .behaviorPreferences(for: behaviorContext())

        switch behaviorPreferences.overlayTap {
        case .dismiss(let closure),
             .tap(let closure):
            closure()
        case .disabled, .passThrough:
            break
        }
    }

    // This function is quite similar to `handlePan`, but with enough differences and edge cases
    // that sharing the logic would be messier than keeping them separate.
    @objc private func handleScroll(gesture: UIPanGestureRecognizer) {
        guard let scrollView = gesture.view as? UIScrollView,
              let presentation = topmostPresentation
        else {
            return
        }

        let offset = gesture.translation(in: presentation.containerView).y
        let context = presentationContext(for: presentation, isInteractive: true)
        let displayValues = presentation.style.displayValues(for: context)
        let exitValues = presentation.style.exitTransitionValues(for: context)
        let dismissDistance = exitValues.frame.minY - displayValues.frame.minY
        var fractionComplete: CGFloat = 0

        // Unlike the pan, which can go in the reverse direction, we don't use abs to compute the
        // fraction complete since we can't go in the reverse direction.
        if dismissDistance > 0, offset > 0 {
            fractionComplete = min(offset / dismissDistance, 1)
        }

        switch gesture.state {
        case .began:

            // Only start tracking the scroll view for dismiss if we're at the top of it,
            // and the scroll view has no refresh control (otherwise we'll disable refreshing)
            let shouldTrackScrollView = scrollView.adjustedContentOffsetY <= 0
                && scrollView.refreshControl == nil

            if shouldTrackScrollView {
                // If we start tracking a scroll, reset the translation of the pan gesture to zero.
                // This fixes an issue if the dismiss starts while the scroll view is scrolled past
                // the top, allowing the scroll view to scroll smoothly down if the dismiss is
                // cancelled, since we set the content offset to zero during a dismiss.
                gesture.setTranslation(.zero, in: scrollView)
                isTrackingScrollViewDismiss = true
            }

        case .changed:

            guard isTrackingScrollViewDismiss else { break }

            let wouldBounce = offset > 0

            // If we're dismissing due to a scroll, and the scroll is positive (dragging down),
            // reset the content offset so we're don't bounce while we drag down. We're checking the
            // pan gesture offset rather than the current content offset since we might still be in a
            // tracking state when we start scrolling back down, in which case we should let
            // the scroll happen.
            if wouldBounce {
                scrollView.contentOffset.y = -scrollView.adjustedContentInset.top
            }

            // This logic is very similar to handlPan, but our criteria for updating the dismiss
            // is whether we're scroll down and at the top of the scroll view. If we're not, we
            // don't do a reverse transition, we simply let the user scroll.
            let isScrollingDownAtTop = offset > 0 && scrollView.adjustedContentOffsetY <= 0

            if isScrollingDownAtTop {
                switch presentation.transitionState {
                case .interactiveDismiss(let animator):
                    animator.fractionComplete = fractionComplete
                case .interactiveInverse(let animator):
                    animator.stopAnimationIfNeeded(withoutFinishing: false)
                    animator.finishAnimation(at: .start)
                    setUpDismissInteraction(for: presentation, fractionComplete: fractionComplete)
                case .entering(let animator):
                    animator.stopAnimationIfNeeded(withoutFinishing: false)
                    animator.finishAnimation(at: .end)
                    setUpDismissInteraction(for: presentation, fractionComplete: fractionComplete)
                case .presented:
                    setUpDismissInteraction(for: presentation, fractionComplete: fractionComplete)
                case .exiting, .pending, .pendingExit, .transitioningSize, .adaptingToKeyboard, .pendingRemoval:
                    break
                }
            } else {
                switch presentation.transitionState {
                case .interactiveInverse(let animator),
                     .interactiveDismiss(let animator):
                    animator.stopAnimationIfNeeded(withoutFinishing: true)
                    transitionIn(presentation: presentation)

                case .presented, .exiting, .pending, .pendingExit, .entering, .transitioningSize, .adaptingToKeyboard, .pendingRemoval:
                    break
                }
            }

        case .cancelled, .ended:
            guard isTrackingScrollViewDismiss else { break }

            isTrackingScrollViewDismiss = false

            switch presentation.transitionState {
            case .interactiveDismiss(let animator),
                 .interactiveInverse(let animator):

                // The animator must be stopped before it's released.
                animator.stopAnimationIfNeeded(withoutFinishing: true)

                let velocity = gesture.velocity(in: presentation.containerView)

                // Prevents bouncing that can occur when the gesture ends. Simply setting
                // `scrollView.contentOffset.y` doesn't cancel the bounce, nor does disabling then
                // re-enabling bounce. But this does the trick for some reason.
                if velocity.y > 0 {
                    scrollView.setContentOffset(
                        CGPoint(
                            x: scrollView.contentOffset.x,
                            y: -scrollView.adjustedContentInset.top
                        ),
                        animated: false
                    )
                }

                let shouldDismissBasedOnProjection = projectShouldDismiss(
                    for: presentation,
                    with: velocity,
                    destinationFrame: exitValues.frame
                )

                let shouldDismiss = shouldDismissBasedOnProjection
                    && gesture.state == .ended
                    && scrollView.adjustedContentOffsetY <= 0

                let behavior = presentation.style.behaviorPreferences(for: ModalBehaviorContext())

                if shouldDismiss, case .swipeDown(let dismiss) = behavior.interactiveDismiss {
                    transitionOut(presentation: presentation, shouldRemove: false, completion: dismiss)
                } else {
                    transitionIn(presentation: presentation)
                }

            default:
                break
            }

        case .failed, .possible:
            break

        @unknown default:
            break
        }
    }

    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        guard let presentation = topmostPresentation else {
            return
        }

        let context = presentationContext(for: presentation, isInteractive: true)
        let displayValues = presentation.style.displayValues(for: context)
        let exitValues = presentation.style.exitTransitionValues(for: context)

        let offset = gesture.translation(in: presentation.containerView).y
        let isInverse = offset < 0
        let dismissDistance = exitValues.frame.minY - displayValues.frame.minY
        let fractionComplete: CGFloat = if dismissDistance > 0 {
            min(abs(offset) / dismissDistance, 1)
        } else {
            0
        }

        // The dismiss interaction animates towards the inverse values with a cubic scrub so it
        // feels like a rubber band. If there are no inverse values provided, panning in the inverse
        // direction does nothing.
        func setUpInverseInteraction() {
            if let reverseValues = presentation.style.reverseTransitionValues(for: context) {

                if case .presented = presentation.transitionState {
                    setUpTransitionOut(presentation: presentation, isInteractive: true)
                }

                let animator = UIViewPropertyAnimator(
                    // This animator is only used for scrubbing, so the duration is unused.
                    duration: 1,
                    // These control points define an ease-out curve.
                    // See visualization at https://cubic-bezier.com/#.33,1,.68,1
                    controlPoint1: CGPoint(x: 0.33, y: 1),
                    controlPoint2: CGPoint(x: 0.68, y: 1)
                ) {
                    presentation.presentationView.set(
                        frame: reverseValues.frame,
                        transform: reverseValues.transform
                    )

                    self.layoutDecorations(for: presentation, opacity: 1, isInteractive: true)
                }

                // Ensure we update our state *before* updating the animation, since starting the
                // animation will cause things to lay out
                presentation.transitionState = .interactiveInverse(animator)
                animator.scrubsLinearly = false
                animator.fractionComplete = fractionComplete
            }
        }

        switch gesture.state {
        case .began, .changed:

            // The logic for updating our transition state is the same, but inverted, based on
            // whether the offset is "inverse" (meaning the offset is in the opposite direction of
            // the dismiss).
            //
            // 1. If we're already in the correct state, we just update the fraction.
            // 2. If we're in the opposite state, stop the animator and set up the current state.
            // 3. If we're in the presented state, just set up the current state
            // 4. Other states shouldn't trigger a pan.
            //

            if isInverse {
                switch presentation.transitionState {
                case .interactiveInverse(let animator):
                    animator.fractionComplete = fractionComplete
                case .interactiveDismiss(let animator):
                    animator.stopAnimationIfNeeded(withoutFinishing: false)
                    animator.finishAnimation(at: .start)
                    setUpInverseInteraction()
                case .entering(let animator):
                    animator.stopAnimationIfNeeded(withoutFinishing: false)
                    animator.finishAnimation(at: .end)
                    setUpInverseInteraction()
                case .presented:
                    setUpInverseInteraction()
                case .exiting, .pending, .pendingExit, .transitioningSize, .adaptingToKeyboard, .pendingRemoval:
                    break
                }
            } else {
                switch presentation.transitionState {
                case .interactiveDismiss(let animator):
                    animator.fractionComplete = fractionComplete
                case .interactiveInverse(let animator):
                    animator.stopAnimationIfNeeded(withoutFinishing: false)
                    animator.finishAnimation(at: .start)
                    setUpDismissInteraction(for: presentation, fractionComplete: fractionComplete)
                case .entering(let animator):
                    animator.stopAnimationIfNeeded(withoutFinishing: false)
                    animator.finishAnimation(at: .end)
                    setUpDismissInteraction(for: presentation, fractionComplete: fractionComplete)
                case .presented:
                    setUpDismissInteraction(for: presentation, fractionComplete: fractionComplete)
                case .exiting, .pending, .pendingExit, .transitioningSize, .adaptingToKeyboard, .pendingRemoval:
                    break
                }
            }

        case .cancelled, .ended:
            switch presentation.transitionState {
            case .interactiveDismiss(let animator),
                 .interactiveInverse(let animator):

                // The animator must be stopped before it's released.
                animator.stopAnimationIfNeeded(withoutFinishing: true)

                let velocity = gesture.velocity(in: presentation.containerView)
                let shouldDismissBasedOnProjection = projectShouldDismiss(
                    for: presentation,
                    with: velocity,
                    destinationFrame: exitValues.frame
                )

                let shouldDismiss = shouldDismissBasedOnProjection
                    && gesture.state == .ended

                let behavior = presentation.style.behaviorPreferences(for: ModalBehaviorContext())

                if shouldDismiss, case .swipeDown(let dismiss) = behavior.interactiveDismiss {
                    transitionOut(presentation: presentation, shouldRemove: false, completion: dismiss)
                } else {
                    transitionIn(presentation: presentation)
                }

            default:
                break
            }

        case .failed, .possible:
            break

        @unknown default:
            break
        }
    }
}

// MARK: - Internal Types

extension ModalPresentationViewController {

    class ContainerView: UIView {
        let overlayView: OverlayView
        let shadowView: ShadowView
        let accessibilityProxyView: AccessibilityProxyView
        var accessibilityDismissal: Presentation.AccessibilityDismissal? {
            didSet {
                overlayView.onAccessibilityActivate = accessibilityDismissal?.activate
                overlayView.accessibilityLabel = accessibilityDismissal?.label
                overlayView.accessibilityHint = accessibilityDismissal?.hint
            }
        }

        /// The passthrough strategy for determining how touches outside of modal content are handled.
        var passThroughOverlayTouches: PassThroughOverlayTouches {
            didSet {
                switch passThroughOverlayTouches {
                case .all:

                    accessibilityProxyView.source = nil

                    if accessibilityProxyView.superview != nil {
                        accessibilityProxyView.removeFromSuperview()
                    }

                case .none(let allowing):
                    accessibilityProxyView.source = allowing

                    if accessibilityProxyView.superview == nil {
                        insertSubview(accessibilityProxyView, belowSubview: shadowView)
                    }
                }

                setNeedsLayout()
            }
        }

        /// If touches within the modal content pass through to layers below.
        var passThroughContentTouches: Bool

        init(modalView: UIView) {
            overlayView = OverlayView()

            shadowView = ShadowView(content: modalView)
            accessibilityProxyView = AccessibilityProxyView()

            passThroughOverlayTouches = .none(allowing: nil)
            passThroughContentTouches = false

            super.init(frame: .zero)

            overlayView.pointInside = { [weak self] in
                guard let self else { return false }
                let insideShadow = shadowView.point(
                    inside: convert($0, to: shadowView),
                    with: $1
                )

                let insidePassthrough = accessibilityProxyView.point(
                    inside: convert($0, to: accessibilityProxyView),
                    with: $1
                )

                return !insideShadow && !insidePassthrough
            }

            addSubview(overlayView)
            addSubview(shadowView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            overlayView.frame = bounds

            switch passThroughOverlayTouches {
            case .all:
                accessibilityProxyView.frame = .zero
            case .none(let allowing):

                if let allowing {
                    accessibilityProxyView.frame = convert(allowing.bounds, from: allowing)
                } else {
                    accessibilityProxyView.frame = .zero
                }
            }
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

            lazy var result = super.hitTest(point, with: event)

            let shadowPoint = convert(point, to: shadowView)

            let isInsideModal = shadowView.point(inside: shadowPoint, with: event)

            if isInsideModal {
                return passThroughContentTouches ? nil : result
            } else {
                switch passThroughOverlayTouches {
                case .all:
                    return nil
                case .none(let allowing):

                    if let allowing {
                        let innerPoint = allowing.convert(point, from: self)

                        if let allowed = allowing.hitTest(innerPoint, with: event) {
                            return allowed
                        }
                    }

                    return result
                }
            }
        }

        enum PassThroughOverlayTouches {
            /// All touches pass through to lower layers.
            case all

            /// No touches pass through to lower layers, except the provided views
            case none(allowing: UIView?)
        }
    }
}

extension ModalPresentationViewController {
    class OverlayView: UIView {
        var pointInside: ((CGPoint, UIEvent?) -> Bool)?
        var onAccessibilityActivate: (() -> Bool)?

        override func accessibilityActivate() -> Bool {
            onAccessibilityActivate?() ?? super.accessibilityActivate()
        }

        override var isAccessibilityElement: Bool {
            get { onAccessibilityActivate != nil }
            set { fatalError("Not settable") }
        }

        override var accessibilityLabel: String? {
            get { super.accessibilityLabel ?? LocalizedStrings.ModalOverlay.dismissPopupAccessibilityLabel }
            set { super.accessibilityLabel = newValue }
        }

        override var accessibilityHint: String? {
            get { super.accessibilityHint ?? LocalizedStrings.ModalOverlay.dismissPopupAccessibilityHint }
            set { super.accessibilityHint = newValue }
        }

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            pointInside?(point, event) ?? super.point(inside: point, with: event)
        }
    }
}

extension ModalPresentationViewController {
    /// Holds all the active references for a modal that is currently being presented.
    ///
    /// Each modal is contained in a few views to provide chrome and clipping, which results in
    /// a view hierarchy similar to the following diagram.
    ///
    /// ```
    /// Root View
    /// ├─Container
    /// | ├─Overlay View
    /// │ ├─Shadow View
    /// │ │ └─Clipping View
    /// │ │   └─Modal
    /// | └─Decoration Views
    /// ├─Container
    /// | ├─Overlay View
    /// │ ├─Shadow View
    /// │ │ └─Clipping View
    /// │ │   └─Modal
    /// | └─Decoration Views
    /// └─Container
    ///   ├─Overlay View
    ///   ├─Shadow View
    ///   │ └─Clipping View
    ///   │   └─Modal
    ///   └─Decoration Views
    /// ```
    ///
    class Presentation {

        /// Configuration for a whole screen accessibility element inserted into the back of the
        /// Accessibility hierarchy to initiate modal dismissal.
        struct AccessibilityDismissal {
            /// Called when the dismissal element is activated, this should dismiss the modal.
            /// Return true if the dismissal was successful.
            var activate: (() -> Bool)?

            /// An override for the default accessibility label of the dismissal element.
            var label: String?
            /// An override for the default accessibility hint of the dismissal element.
            var hint: String?
        }


        let containerViewController: ContainerViewController
        let viewController: UIViewController
        let onDidPresent: (() -> Void)?

        var style: ModalPresentationStyle

        var behaviorPreferences: ModalBehaviorPreferences {
            didSet {
                containerViewController.behaviorPreferences = behaviorPreferences
            }
        }

        /// Visibility of the `ModalPresentationViewController` itself.
        ///
        /// Changing the container visibility may cause view controller lifecycle events to be
        /// invoked on the modal.
        var containerVisibility: Visibility {
            didSet {
                let start = transitionState.visibility.within(containerState: oldValue)
                let end = transitionState.visibility.within(containerState: containerVisibility)
                containerViewController.callAppearanceTransitions(
                    from: start,
                    to: end,
                    animated: true
                )
            }
        }

        /// The state of the modal. See `TransitionState` for a description of each state.
        ///
        ///
        /// Changing the state has side effects:
        /// - animators attached to the previous state will be stopped
        /// - view controller lifecycle events may be invoked
        ///
        /// However, changing the state is an idempotent operation: setting it to the same value a
        /// second time will have no effect.
        var transitionState: TransitionState {
            willSet {
                ModalsLogging.logger.debug("Modal \(viewController) will transition from \(transitionState) to \(newValue)")

                guard let animator = transitionState.animator,
                      animator != newValue.animator
                else {
                    return
                }

                animator.stopAnimationIfNeeded(withoutFinishing: true)
            }

            didSet {
                let start = oldValue.visibility.within(containerState: containerVisibility)
                let end = transitionState.visibility.within(containerState: containerVisibility)
                containerViewController.callAppearanceTransitions(
                    from: start,
                    to: end,
                    animated: true
                )
            }
        }

        /// This view contains all other views.
        /// Its frame matches the containing view controller, not the modal.
        var containerView: ContainerView {
            containerViewController.view as! ContainerView
        }

        var decorationViews: [UIView]

        /// This is the outermost view whose frame matches that of the modal itself. Use this view
        /// when using the modal frame or alpha.
        var presentationView: UIView {
            shadowView
        }

        /// The frame of the `presentationView`, adjusted for any in-flight animations.
        var presentationFrame: CGRect {
            // Use the presentation layer (if there is one) to get the on-screen frame, since we
            // might be in the middle of an animation.
            presentationView.presentationOrRealLayer.frame
        }

        var clippingView: ClippingView {
            shadowView.clippingView
        }

        var overlayView: OverlayView {
            containerView.overlayView
        }

        var shadowView: ShadowView {
            containerView.shadowView
        }

        var currentFrame: ModalPresentationContext.CurrentFrame {
            switch transitionState {
            case .presented,
                 .transitioningSize,
                 .adaptingToKeyboard,
                 .pendingExit:
                .known(presentationFrame)
            default:
                .undefined
            }
        }

        init(
            viewController: UIViewController,
            onDidPresent: (() -> Void)?,
            style: ModalPresentationStyle,
            containerVisibility: Visibility,
            behaviorPreferences: ModalBehaviorPreferences,
            transitionState: ModalPresentationViewController.TransitionState,
            presentationView: UIView?,
            accessibilityDismissal: AccessibilityDismissal
        ) {
            decorationViews = []

            containerViewController = ContainerViewController(
                content: viewController,
                behaviorPreferences: behaviorPreferences
            )

            containerViewController.presentationView = presentationView

            self.viewController = viewController
            self.onDidPresent = onDidPresent
            self.style = style
            self.containerVisibility = containerVisibility
            self.behaviorPreferences = behaviorPreferences

            self.transitionState = transitionState
            containerView.accessibilityDismissal = accessibilityDismissal
        }

        deinit {
            transitionState.animator?.stopAnimationIfNeeded(withoutFinishing: true)
        }
    }

    enum TransitionState: Equatable, CustomStringConvertible {
        /// The modal has been aggregated but not yet presented. It should be transitioned in when
        /// presentations are updated.
        case pending

        /// The modal is in the process of animating to the presented state.
        case entering(UIViewPropertyAnimator)

        /// The modal is fully presented.
        case presented

        /// The modal is in the process of transitioning to a new size. All non-exiting modals go
        /// into this state when the presentation view controller transitions sizes.
        case transitioningSize

        /// The modal is in the process of adapting to the keyboard.
        case adaptingToKeyboard(UIViewPropertyAnimator)

        /// The modal is currently being interactively dismissed.
        case interactiveDismiss(UIViewPropertyAnimator)

        /// The modal is currently being interactively dismissed, but the gesture is in the opposite
        /// direction of dismissal so any "inverse" appearance values are being applied.
        case interactiveInverse(UIViewPropertyAnimator)

        /// The modal has been removed from the aggregated list of modals. It should be transitioned
        /// out when presentations are updated.
        case pendingExit

        /// The modal is in the process of animating to the dismissed state.
        case exiting(UIViewPropertyAnimator)

        /// The terminal state of modals, before being from the view hierarchy.
        ///
        /// Also used when a modal was dismissed by an interactive dismissal, but has not yet been
        /// removed from the aggregated list of modals in a modal update. We keep interactively
        /// dismissed modals in this state so that they aren't re-presented accidentally if a modal
        /// update happens before the presenting infrastructure has a chance to react to the
        /// dismissal and remove the modal from its aggregation.
        case pendingRemoval

        var isInteracting: Bool {
            switch self {
            case .interactiveDismiss,
                 .interactiveInverse:
                true
            default:
                false
            }
        }

        var animator: UIViewPropertyAnimator? {
            switch self {
            case .interactiveDismiss(let animator),
                 .interactiveInverse(let animator),
                 .entering(let animator),
                 .exiting(let animator),
                 .adaptingToKeyboard(let animator):
                animator

            case .pending,
                 .transitioningSize,
                 .pendingExit,
                 .pendingRemoval,
                 .presented:
                nil
            }
        }

        /// The visibility that a modal's view controller should be in when it's in this state.
        var visibility: Visibility {
            switch self {
            case .pending:
                .disappeared
            case .entering:
                .appearing
            case .interactiveInverse:
                // Modeled after UIKit sheets
                .appearing
            case .presented:
                .appeared
            case .transitioningSize:
                .appeared
            case .adaptingToKeyboard:
                .appeared
            case .pendingExit:
                .appeared
            case .exiting:
                .disappearing
            case .interactiveDismiss:
                .disappearing
            case .pendingRemoval:
                .disappeared
            }
        }

        var description: String {
            switch self {
            case .pending:
                "pending"
            case .entering:
                "entering"
            case .presented:
                "presented"
            case .transitioningSize:
                "transitioningSize"
            case .adaptingToKeyboard:
                "adaptingToKeyboard"
            case .interactiveDismiss:
                "interactiveDismiss"
            case .interactiveInverse:
                "interactiveInverse"
            case .pendingExit:
                "pendingExit"
            case .exiting:
                "exiting"
            case .pendingRemoval:
                "pendingRemoval"
            }
        }
    }

    /// An object which is responsible for finding a scroll view in a view controller hierarchy that:
    ///
    /// 1. Has a non-zero frame
    /// 2. Has a frame matching its view controllers view bounds
    ///
    /// Note that the criteria for (2) is not that it matches the view controller you specify;
    /// the scroll view might be found in a child view controller (e.g., if the outer view controller
    /// is a navigation controller), so we just want to check that the scroll view is the main view of
    /// the view controller it's found in.
    ///
    final class TrackedScrollViewFinder {

        // The view to find scroll views in.
        var viewController: UIViewController?

        // The most recently discovered scroll view. Update by calling `updateTrackedScrollView`.
        private(set) weak var scrollView: UIScrollView?

        init() {}

        /// Update the currently tracked scroll view.
        /// - Parameter ifChanged: If a new scroll was found, or there is no longer a scroll view when
        ///                        there previously was, this block is called with the old scroll view
        ///                        as its first argument and the new scroll view as its second.
        func updateTrackedScrollView(ifChanged: (UIScrollView?, UIScrollView?) -> Void = { _, _ in }) {
            let newScrollView = viewController?.view.findScrollView()

            if newScrollView != scrollView {
                let oldScrollView = scrollView
                scrollView = newScrollView

                ifChanged(oldScrollView, newScrollView)
            }
        }
    }
}

// MARK: - Extensions

extension [ModalPresentationViewController.Presentation] {
    func index(of viewController: UIViewController) -> Int? {
        firstIndex(where: { $0.viewController == viewController })
    }

    func presentation(for viewController: UIViewController) -> Element? {
        first(where: { $0.viewController == viewController })
    }
}

extension UIScrollView {
    /// The `contentOffset.y` normalized against the `adjustedContentInset.top`.
    ///
    /// A value of 0 indicates that the scroll view is effectively scrolled to the top of its
    /// adjusted content, a positive value indicates the scroll view is scrolled down, and a
    /// negative value indicates that the scroll view is "bouncing".
    fileprivate var adjustedContentOffsetY: CGFloat {
        contentOffset.y + adjustedContentInset.top
    }
}

extension UIView {

    /// Finds the scroll view which should be tracked within a given view.
    ///
    /// The tracked scroll view is a `UIScrollView` instance which is
    /// the same width as its view controllers view, or is its view controllers view.
    ///
    fileprivate func findScrollView() -> UIScrollView? {
        recursiveFindScrollView()
    }

    private func recursiveFindScrollView() -> UIScrollView? {
        if let scrollView = self as? UIScrollView {

            // Track the scroll view if:
            //
            // 1. The frame isn't zero, otherwise we can't really infer anything
            //   from matching our parents view width
            // 2. The scroll view is in a view controller
            // 3. The scroll view width and x origin equals the view controllers
            //
            // We don't keep recursing once we find a scroll view - we only want to track
            // the first one found in the hierarchy.
            //

            guard scrollView.frame != .zero,
                  let viewController = scrollView.findViewController(),
                  scrollView.frame.width == viewController.view.bounds.width,
                  scrollView.frame.origin.x == 0
            else {
                return nil
            }

            return scrollView
        }

        for subview in subviews {
            if let found = subview.recursiveFindScrollView() {
                return found
            }
        }

        return nil
    }
}

extension UIView {
    // https://www.hackingwithswift.com/example-code/uikit/how-to-find-the-view-controller-responsible-for-a-view
    private func findViewController() -> UIViewController? {
        if let nextResponder = next as? UIViewController {
            nextResponder
        } else if let nextResponder = next as? UIView {
            nextResponder.findViewController()
        } else {
            nil
        }
    }
}

extension UIEdgeInsets {
    fileprivate static func - (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: lhs.top - rhs.top,
            left: lhs.left - rhs.left,
            bottom: lhs.bottom - rhs.bottom,
            right: lhs.right - rhs.right
        )
    }
}

extension ModalPresentationViewController {
    /// Since ``ModalPresentationViewController`` may be laid out in a smaller frame than its
    /// `ancestorPresentationView`, it may not have the same safe area insets, but since modals are
    /// laid out in the `ancestorPresentationView` coordinate space, they need to have safe area
    /// insets that match it.
    ///
    /// ``ContainerViewController`` monitors `viewSafeAreaInsetsDidChange` and
    /// `viewDidLayoutSubviews`, and applies the insets from `presentationView` that intersect with
    /// its frame as additional safe area insets. This ensures the wrapped modal content has the
    /// correct safe area insets for its position on screen.
    ///
    class ContainerViewController: UIViewController {

        var behaviorPreferences: ModalBehaviorPreferences {
            didSet {
                updateNeedsPreferredContentSize()
            }
        }

        weak var presentationView: UIView? {
            didSet { updateAdditionalSafeAreaInsets() }
        }

        fileprivate let content: UIViewController

        override func loadView() {
            view = ContainerView(modalView: content.view)
        }

        init(
            content: UIViewController,
            behaviorPreferences: ModalBehaviorPreferences
        ) {
            self.content = content
            self.behaviorPreferences = behaviorPreferences

            super.init(nibName: nil, bundle: nil)

            updateNeedsPreferredContentSize()

            addChild(content)
            content.didMove(toParent: self)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            updateAdditionalSafeAreaInsets()
        }

        override func viewSafeAreaInsetsDidChange() {
            super.viewSafeAreaInsetsDidChange()
            updateAdditionalSafeAreaInsets()
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            preferredContentSize = content.preferredContentSize
        }

        override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
            super.preferredContentSizeDidChange(forChildContentContainer: container)

            if preferredContentSize != content.preferredContentSize {
                preferredContentSize = content.preferredContentSize
            }
        }

        private func updateNeedsPreferredContentSize() {
            presentationContextWantsPreferredContentSize = behaviorPreferences.usesPreferredContentSize
        }

        private func updateAdditionalSafeAreaInsets() {
            guard let presentationView else {
                if additionalSafeAreaInsets != .zero {
                    additionalSafeAreaInsets = .zero
                }

                return
            }

            let viewSafeAreaInsets = view.safeAreaInsets - additionalSafeAreaInsets
            let convertedSafeAreaInsets = presentationView.convert(presentationView.safeAreaInsets, to: view)
            let newAdditionalSafeAreaInsets = convertedSafeAreaInsets - viewSafeAreaInsets

            if newAdditionalSafeAreaInsets != additionalSafeAreaInsets {
                additionalSafeAreaInsets = newAdditionalSafeAreaInsets
            }
        }
    }
}

extension ModalPresentationViewController {

    /// Represents a layer of the modal hierarchy that requires management of the accessibility focus.
    private struct AccessibilityLayer: Equatable {
        var viewController: UIViewController
        var containerView: ContainerView?

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.viewController === rhs.viewController
        }
    }

    /// Represents a layer of the modal hierarchy that requires management of the first responder in terms
    /// of focus recording/persistence and restoration when the associated view controller is presented
    /// and dismissed.
    private struct FocusableLayer: Equatable {
        var content: UIViewController

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.content === rhs.content
        }
    }
}

// MARK: KeyboardObserverDelegate

extension ModalPresentationViewController: KeyboardObserverDelegate {

    func keyboardFrameWillChange(
        for observer: KeyboardObserver,
        animationDuration: Double,
        animationCurve: UIView.AnimationCurve
    ) {
        switch observer.currentFrame(in: presentationView) {
        case .nonOverlapping, .none:
            keyboardFrame = nil
        case .overlapping(let frame):
            keyboardFrame = frame
        }

        // Check if any presentations need to respond to keyboard (or require
        // special handling).

        let keyboardResponsivePresentations = allPresentations.filter { presentation in
            let behaviourPreferences = presentation.style.behaviorPreferences(
                for: behaviorContext()
            )

            guard behaviourPreferences.adjustsForKeyboard else {
                return false
            }

            switch presentation.transitionState {
            case .pendingExit,
                 .exiting,
                 .pendingRemoval,
                 .interactiveDismiss,
                 .interactiveInverse:
                // Don't respond if we're exiting or interactively dismissing.
                return false
            case .transitioningSize:
                // If the keyboard is up while transitioning size then a keyboard
                // notification should be posted after the transition.
                return false
            case .pending:
                // Avoid interfering with the normal `.pending` -> `.entering`
                // transition. Any keyboard frame changes occurring during
                // `.pending` will be reflected in the `.entering` animations.
                return false
            case .adaptingToKeyboard(let animator):
                // Stop any previous keyboard adapting animations and let this
                // one take over.
                animator.stopAnimationIfNeeded(withoutFinishing: true)
                return true
            case .entering:
                // We avoid appending to the existing animator since there are
                // cases when the keyboard change occurs very late in the
                // existing animation and attempts to extend the animation were
                // unreliable. Instead, the `.entering` state will handle any
                // changes to the frame upon completion (starting a new
                // animation if necessary).
                return false
            case .presented:
                return true
            }
        }

        guard keyboardResponsivePresentations.isEmpty == false else { return }

        // NOTE: During rotation, `UIView.areAnimationEnabled` is set to `false`
        // which prevents the keyboard adaptation from animating properly.
        // If needed, we re-enable them long enough to add our own animations.
        var needsDisableAnimations = false
        if UIView.areAnimationsEnabled == false {
            needsDisableAnimations = true
            UIView.setAnimationsEnabled(true)
        }

        for presentation in keyboardResponsivePresentations {
            let animator = UIViewPropertyAnimator(
                duration: animationDuration,
                curve: animationCurve
            ) {
                self.layout(
                    presentation: presentation,
                    isInteractive: presentation.transitionState.isInteracting
                )
            }

            animator.addCompletion { _ in
                presentation.transitionState = .presented
            }

            presentation.transitionState = .adaptingToKeyboard(animator)

            animator.startAnimation()
        }

        if needsDisableAnimations {
            UIView.setAnimationsEnabled(false)
        }
    }
}
