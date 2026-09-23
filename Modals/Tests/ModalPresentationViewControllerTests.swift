import XCTest
@testable import Logging
@testable import Modals

final class ModalPresentationViewControllerTests: XCTestCase {

    func test_withdraw_before_loading_does_not_load_or_later_attach_modal() {
        let content = UIViewController()
        let subject = ModalPresentationViewController(content: content)
        let presented = UIViewController()

        subject.update(modals: [modal(for: presented)])
        subject.update(modals: [])

        XCTAssertFalse(subject.isViewLoaded)
        XCTAssertFalse(presented.isViewLoaded)

        subject.loadViewIfNeeded()
        XCTAssertEqual(subject.children, [content])
        XCTAssertNil(presented.viewIfLoaded?.window)
    }

    func test_removalCallback_visible_presenter() throws {
        try assertRemovalCallback(visibility: .appeared)
    }

    func test_removalCallback_disappeared_presenter() throws {
        try assertRemovalCallback(visibility: .disappeared)
    }

    func test_removalCallback_hidden_window() throws {
        try assertRemovalCallback(visibility: .appeared, hiddenWindow: true)
    }

    func test_removalCallback_zero_duration() throws {
        try assertRemovalCallback(visibility: .appeared, duration: 0)
    }

    func test_existing_trailing_callback_still_observes_presentation() throws {
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.loadViewIfNeeded()
        var count = 0
        let modal = PresentableModal(
            viewController: UIViewController(),
            presentationStyle: TestFullScreenStyle(animation: .curve(.linear, duration: 1)),
            info: .empty()
        ) {
            count += 1
        }

        subject.update(modals: [modal])
        let presentation = try XCTUnwrap(subject.topmostPresentation)
        finishTransition(presentation)
        XCTAssertEqual(count, 1)
        subject.update(modals: [])
        finishTransition(presentation)
        XCTAssertEqual(count, 1)
    }

    func test_removalCallback_loaded_reentrant_update_keeps_new_presentation() throws {
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.loadViewIfNeeded()
        let replacement = UIViewController()
        var count = 0
        let removed = expectation(description: "Removal updated presentation")
        let modal = removalModal(for: UIViewController(), duration: 0) {
            count += 1
            XCTAssertFalse(subject.hasModals)
            subject.update(modals: [self.modal(for: replacement)])
            removed.fulfill()
        }

        subject.update(modals: [modal])
        let presentation = try XCTUnwrap(subject.topmostPresentation)
        finishTransition(presentation)
        subject.update(modals: [])
        finishTransition(presentation)
        wait(for: [removed], timeout: 2)

        XCTAssertEqual(count, 1)
        XCTAssertEqual(subject.presentedViewControllers, [replacement])
        XCTAssertTrue(replacement.parent?.parent === subject)
        finishTransition(try XCTUnwrap(subject.topmostPresentation))
        subject.update(modals: [])
    }

    func test_removalCallback_unloaded_and_reentrant_update() {
        let content = UIViewController()
        let subject = ModalPresentationViewController(content: content)
        let first = UIViewController()
        let second = UIViewController()
        var callbacks: [String] = []

        let secondModal = removalModal(for: second) {
            callbacks.append("second")
        }
        let firstModal = removalModal(for: first) {
            callbacks.append("first")
            XCTAssertFalse(subject.hasModals)
            XCTAssertEqual(subject.children, [content])
            XCTAssertFalse(subject.isViewLoaded)
            subject.update(modals: [secondModal])
            subject.update(modals: [])
            callbacks.append("first returned")
        }

        subject.update(modals: [firstModal])
        subject.update(modals: [])
        subject.update(modals: [])

        XCTAssertEqual(callbacks, ["first", "first returned", "second"])
        XCTAssertFalse(subject.isViewLoaded)
        XCTAssertFalse(first.isViewLoaded)
        XCTAssertFalse(second.isViewLoaded)
        subject.loadViewIfNeeded()
        XCTAssertEqual(subject.children, [content])
    }

    func test_removalCallback_uses_latest_callback_including_nil() {
        let subject = ModalPresentationViewController(content: UIViewController())
        let presented = UIViewController()
        var callbacks: [String] = []

        subject.update(modals: [removalModal(for: presented) { callbacks.append("original") }])
        subject.update(modals: [removalModal(for: presented) { callbacks.append("updated") }])
        subject.update(modals: [])
        XCTAssertEqual(callbacks, ["updated"])

        subject.update(modals: [removalModal(for: presented) { callbacks.append("cleared") }])
        subject.update(modals: [removalModal(for: presented, onDidRemove: nil)])
        subject.update(modals: [])
        XCTAssertEqual(callbacks, ["updated"])
    }

    func test_removalCallback_replaced_controller_and_reused_controller_are_distinct_instances() {
        let subject = ModalPresentationViewController(content: UIViewController())
        let first = UIViewController()
        let second = UIViewController()
        var callbacks: [String] = []

        subject.update(modals: [removalModal(for: first) { callbacks.append("first") }])
        subject.update(modals: [removalModal(for: second) { callbacks.append("second") }])
        XCTAssertEqual(callbacks, ["first"])
        XCTAssertEqual(subject.presentedViewControllers, [second])

        subject.update(modals: [])
        subject.update(modals: [removalModal(for: first) { callbacks.append("first again") }])
        subject.update(modals: [])
        XCTAssertEqual(callbacks, ["first", "second", "first again"])
    }

    func test_removalCallback_removing_during_entry_and_repeated_exit_updates() throws {
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.loadViewIfNeeded()
        var count = 0
        let modal = removalModal(for: UIViewController()) { count += 1 }
        subject.update(modals: [modal])
        let presentation = try XCTUnwrap(subject.topmostPresentation)
        guard case .entering = presentation.transitionState else {
            return XCTFail("Expected an unfinished entry")
        }

        subject.update(modals: [])
        subject.update(modals: [])
        XCTAssertEqual(count, 0)
        finishTransition(presentation)
        subject.update(modals: [])
        XCTAssertEqual(count, 1)
        XCTAssertNil(presentation.containerViewController.parent)
    }

    func test_removalCallback_cancelled_interaction_is_not_removal() throws {
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.loadViewIfNeeded()
        var count = 0
        subject.update(modals: [removalModal(for: UIViewController()) { count += 1 }])
        let presentation = try XCTUnwrap(subject.topmostPresentation)
        finishTransition(presentation)

        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear)
        presentation.transitionState = .interactiveDismiss(animator)
        animator.startAnimation()
        animator.pauseAnimation()
        subject.transitionIn(presentation: presentation)
        finishTransition(presentation)
        XCTAssertEqual(count, 0)
        XCTAssertTrue(subject.hasModals)

        // Interactive dismissal finishes visually before its producer withdraws the modal.
        presentation.transitionState = .pendingRemoval
        XCTAssertEqual(count, 0)
        subject.update(modals: [])
        finishTransition(presentation)
        XCTAssertEqual(count, 1)
    }

    func test_removalCallback_presenter_destruction_does_not_notify() {
        var count = 0
        weak var weakSubject: ModalPresentationViewController?
        autoreleasepool {
            let subject = ModalPresentationViewController(content: UIViewController())
            weakSubject = subject
            subject.update(modals: [removalModal(for: UIViewController()) { count += 1 }])
        }
        XCTAssertNil(weakSubject)
        XCTAssertEqual(count, 0)
    }

    private func assertRemovalCallback(
        visibility: Visibility,
        hiddenWindow: Bool = false,
        duration: TimeInterval = 1
    ) throws {
        let content = UIViewController()
        let subject = ModalPresentationViewController(content: content)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.rootViewController = subject
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        let remaining = UIViewController()
        subject.update(modals: [modal(for: remaining)])
        finishTransition(try XCTUnwrap(subject.topmostPresentation))
        let remainingContainer = try XCTUnwrap(remaining.parent)

        let presented = UIViewController()
        var removedContainer: UIViewController?
        var count = 0
        let removed = expectation(description: "Physically removed")
        let modal = removalModal(for: presented, duration: duration) {
            count += 1
            XCTAssertNil(removedContainer?.parent)
            XCTAssertNil(removedContainer?.viewIfLoaded?.superview)
            XCTAssertNil(presented.viewIfLoaded?.window)
            XCTAssertEqual(subject.children, [content, remainingContainer])
            XCTAssertEqual(subject.presentedViewControllers, [remaining])
            XCTAssertTrue(remainingContainer.view.accessibilityViewIsModal)
            removed.fulfill()
        }
        subject.update(modals: [self.modal(for: remaining), modal])
        let presentation = try XCTUnwrap(subject.topmostPresentation)
        finishTransition(presentation)
        removedContainer = presentation.containerViewController

        if visibility == .disappeared {
            subject.beginAppearanceTransition(false, animated: false)
            subject.endAppearanceTransition()
        }
        window.isHidden = hiddenWindow
        XCTAssertEqual(count, 0)
        subject.update(modals: [self.modal(for: remaining)])
        finishTransition(presentation)
        wait(for: [removed], timeout: 2)
        subject.update(modals: [self.modal(for: remaining)])
        XCTAssertEqual(count, 1)
    }

    private func removalModal(
        for viewController: UIViewController,
        duration: TimeInterval = 1,
        onDidRemove: (() -> Void)?
    ) -> PresentableModal {
        PresentableModal(
            viewController: viewController,
            presentationStyle: TestFullScreenStyle(animation: .curve(.linear, duration: duration)),
            info: .empty(),
            onDidRemove: onDidRemove,
            onDidPresent: nil
        )
    }

    private func finishTransition(_ presentation: ModalPresentationViewController.Presentation) {
        guard let animator = presentation.transitionState.animator, animator.state == .active else { return }
        animator.stopAnimation(false)
        animator.finishAnimation(at: .end)
    }

    func test_no_leaks_on_teardown() {

        class LifetimeHoldingViewController: UIViewController {
            var lifetime: ModalLifetime?

            func present(vc: UIViewController) {
                lifetime = modalPresenter.present(vc, style: .testFull())
            }
        }

        weak var weakHostContainer: ModalHostContainerViewController?
        weak var weakRoot: UIViewController?
        weak var weakLeaf: UIViewController?

        autoreleasepool {
            let root = LifetimeHoldingViewController()

            var hostContainer: ModalHostContainerViewController? = ModalHostContainerViewController(content: root)

            let leaf = UIViewController()

            root.present(vc: leaf)

            // Capture weak references to validate they are deallocated
            // when the host container goes away.
            weakHostContainer = hostContainer
            weakRoot = root
            weakLeaf = leaf

            XCTAssertNotNil(weakHostContainer)
            XCTAssertNotNil(weakRoot)
            XCTAssertNotNil(weakLeaf)

            // Remove reference to the host. Everything should get torn down.
            hostContainer = nil
        }

        XCTAssertNil(weakHostContainer)
        XCTAssertNil(weakRoot)
        XCTAssertNil(weakLeaf)
    }

    func test_should_log_on_presentation_and_dismissal() throws {
        let handler = TestLogHandler()

        let content = UIViewController()
        let subject = ModalPresentationViewController(content: content)
        subject.logger = Logger(label: ModalsLogging.defaultLoggerLabel, handler)

        let controllers: [UIViewController] = [content, UIViewController(), UIViewController()]
        var presentations: [PresentableModal] = []

        presentations.append(modal(for: controllers[1]))

        // First presentation
        subject.loadViewIfNeeded()
        subject.update(modals: presentations)

        do {
            XCTAssertEqual(handler.logs.count, 1)
            let payload = try XCTUnwrap(handler.logs.last)

            XCTAssert(payload.message.description.contains(/will transition/))

            let event = try XCTUnwrap(ModalPresentationWillTransitionLogEvent(metadata: payload.metadata!))
            XCTAssertEqual(event.presenterViewController, subject)
            XCTAssertEqual(event.fromViewController, controllers[0])
            XCTAssertEqual(event.toViewController, controllers[1])
            XCTAssertEqual(event.transitionState, .entering)
        }

        // Second presentation
        presentations.append(modal(for: controllers[2]))
        subject.update(modals: presentations)

        do {
            XCTAssertEqual(handler.logs.count, 2)
            let payload = try XCTUnwrap(handler.logs.last)

            XCTAssert(payload.message.description.contains(/will transition/))

            let event = try XCTUnwrap(ModalPresentationWillTransitionLogEvent(metadata: payload.metadata!))
            XCTAssertEqual(event.presenterViewController, subject)
            XCTAssertEqual(event.fromViewController, controllers[1])
            XCTAssertEqual(event.toViewController, controllers[2])
            XCTAssertEqual(event.transitionState, .entering)
        }

        // First dismissal
        presentations.removeLast()
        subject.update(modals: presentations)

        do {
            XCTAssertEqual(handler.logs.count, 3)
            let payload = try XCTUnwrap(handler.logs.last)

            XCTAssert(payload.message.description.contains(/will transition/))

            let event = try XCTUnwrap(ModalPresentationWillTransitionLogEvent(metadata: payload.metadata!))
            XCTAssertEqual(event.presenterViewController, subject)
            XCTAssertEqual(event.fromViewController, controllers[2])
            XCTAssertEqual(event.toViewController, controllers[1])
            XCTAssertEqual(event.transitionState, .exiting)
        }

        // Second dismissal
        presentations.removeLast()
        subject.update(modals: presentations)

        do {
            XCTAssertEqual(handler.logs.count, 4)
            let payload = try XCTUnwrap(handler.logs.last)

            XCTAssert(payload.message.description.contains(/will transition/))

            let event = try XCTUnwrap(ModalPresentationWillTransitionLogEvent(metadata: payload.metadata!))
            XCTAssertEqual(event.presenterViewController, subject)
            XCTAssertEqual(event.fromViewController, controllers[1])
            XCTAssertEqual(event.toViewController, controllers[0])
            XCTAssertEqual(event.transitionState, .exiting)
        }
    }

    // MARK: - Accessibility

    func test_accessibilityViewIsModal_restored_after_nested_dismiss() {
        let content = UIViewController()
        let subject = ModalPresentationViewController(content: content)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.rootViewController = subject
        window.makeKeyAndVisible()

        let modalA = UIViewController()
        let modalB = UIViewController()

        // Present modal A
        subject.update(modals: [modal(for: modalA)])

        // Find modal A's ContainerView
        let containerViews = subject.view.subviews.filter {
            String(describing: type(of: $0)).contains("ContainerView")
        }
        XCTAssertEqual(containerViews.count, 1, "Expected one ContainerView after presenting modal A")
        let containerA = containerViews[0]
        XCTAssertTrue(
            containerA.accessibilityViewIsModal,
            "Modal A's ContainerView should have accessibilityViewIsModal = true"
        )

        // Present modal B on top of A
        subject.update(modals: [modal(for: modalA), modal(for: modalB)])

        // Now modal B's container should be modal, A's should not
        let containerViewsAfterB = subject.view.subviews.filter {
            String(describing: type(of: $0)).contains("ContainerView")
        }
        XCTAssertEqual(containerViewsAfterB.count, 2, "Expected two ContainerViews after presenting modal B")

        // Dismiss modal B — only A remains
        subject.update(modals: [modal(for: modalA)])

        // Wait for the exit animation to complete
        let expectation = expectation(description: "animation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Modal A's ContainerView should have accessibilityViewIsModal restored to true
        let containerViewsAfterDismiss = subject.view.subviews.filter {
            String(describing: type(of: $0)).contains("ContainerView")
        }
        XCTAssertEqual(containerViewsAfterDismiss.count, 1, "Expected one ContainerView after dismissing modal B")
        XCTAssertTrue(
            containerViewsAfterDismiss[0].accessibilityViewIsModal,
            "BUG: Modal A's ContainerView has accessibilityViewIsModal = false after nested dismiss. Parent screen elements will leak through."
        )

        window.resignKey()
        window.isHidden = true
    }

    func modal(for vc: UIViewController) -> PresentableModal {
        PresentableModal(
            viewController: vc,
            presentationStyle: TestFullScreenStyle(),
            info: .empty(),
            onDidPresent: nil
        )
    }
}
