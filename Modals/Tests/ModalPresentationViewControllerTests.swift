import XCTest
@testable import Logging
@testable import Modals

final class ModalPresentationViewControllerTests: XCTestCase {

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
