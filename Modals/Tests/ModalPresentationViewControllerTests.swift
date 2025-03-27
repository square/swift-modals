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
            let metadata = try XCTUnwrap(payload.metadata)

            XCTAssert(payload.message.description.contains(/will transition/))
            XCTAssertEqual(metadata["presenterViewController"], .stringConvertible(subject))
            XCTAssertEqual(metadata["fromViewController"], .stringConvertible(controllers[0]))
            XCTAssertEqual(metadata["toViewController"], .stringConvertible(controllers[1]))
            XCTAssertEqual(metadata["transitionState"], .stringConvertible("entering"))
        }

        // Second presentation
        presentations.append(modal(for: controllers[2]))
        subject.update(modals: presentations)

        do {
            XCTAssertEqual(handler.logs.count, 2)
            let payload = try XCTUnwrap(handler.logs.last)
            let metadata = try XCTUnwrap(payload.metadata)

            XCTAssert(payload.message.description.contains(/will transition/))
            XCTAssertEqual(metadata["presenterViewController"], .stringConvertible(subject))
            XCTAssertEqual(metadata["fromViewController"], .stringConvertible(controllers[1]))
            XCTAssertEqual(metadata["toViewController"], .stringConvertible(controllers[2]))
            XCTAssertEqual(metadata["transitionState"], .stringConvertible("entering"))
        }

        // First dismissal
        presentations.removeLast()
        subject.update(modals: presentations)

        do {
            XCTAssertEqual(handler.logs.count, 3)
            let payload = try XCTUnwrap(handler.logs.last)
            let metadata = try XCTUnwrap(payload.metadata)

            XCTAssert(payload.message.description.contains(/will transition/))
            XCTAssertEqual(metadata["presenterViewController"], .stringConvertible(subject))
            XCTAssertEqual(metadata["fromViewController"], .stringConvertible(controllers[2]))
            XCTAssertEqual(metadata["toViewController"], .stringConvertible(controllers[1]))
            XCTAssertEqual(metadata["transitionState"], .stringConvertible("exiting"))
        }

        // Second dismissal
        presentations.removeLast()
        subject.update(modals: presentations)

        do {
            XCTAssertEqual(handler.logs.count, 4)
            let payload = try XCTUnwrap(handler.logs.last)
            let metadata = try XCTUnwrap(payload.metadata)

            XCTAssert(payload.message.description.contains(/will transition/))
            XCTAssertEqual(metadata["presenterViewController"], .stringConvertible(subject))
            XCTAssertEqual(metadata["fromViewController"], .stringConvertible(controllers[1]))
            XCTAssertEqual(metadata["toViewController"], .stringConvertible(controllers[0]))
            XCTAssertEqual(metadata["transitionState"], .stringConvertible("exiting"))
        }
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
