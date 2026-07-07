import TestingSupport
import UIKit
import XCTest
@testable import Modals

final class HostToastPresentingTests: XCTestCase {

    func test_presents_from_host_content() {
        let content = UIViewController()
        let host = ModalHostContainerViewController(content: content)

        let lifetime = host.contentToastPresenter.present(
            UIViewController(),
            style: .init(ToastPresentationStyleFixture()),
            accessibilityAnnouncement: "Toast."
        )

        // The toast is owned by the host's content, making it visible to the host's aggregation.
        XCTAssertEqual(content.aggregateModals().toasts.count, 1)

        show(vc: host) { host in
            XCTAssertTrue(host.toastPresentation.hasVisiblePresentations)

            lifetime.dismiss()
            XCTAssertEqual(content.aggregateModals().toasts.count, 0)
        }
    }

    func test_toast_outlives_presenting_descendent() {
        let content = UIViewController()
        let screen = UIViewController()
        content.addChild(screen)
        content.view.addSubview(screen.view)
        screen.didMove(toParent: content)

        let host = ModalHostContainerViewController(content: content)

        let lifetime = host.contentToastPresenter.present(
            UIViewController(),
            style: .init(ToastPresentationStyleFixture()),
            accessibilityAnnouncement: "Toast."
        )
        defer { lifetime.dismiss() }

        // Remove the view controller that triggered the toast, as a navigation pop would.
        screen.willMove(toParent: nil)
        screen.view.removeFromSuperview()
        screen.removeFromParent()

        XCTAssertEqual(
            content.aggregateModals().toasts.count,
            1,
            "The toast should remain presented after the triggering view controller is removed."
        )
    }

    func test_host_is_reachable_from_descendents() {
        let content = UIViewController()
        let screen = UIViewController()
        content.addChild(screen)
        content.view.addSubview(screen.view)
        screen.didMove(toParent: content)

        let host = ModalHostContainerViewController(content: content)

        show(vc: host) { host in
            let found = screen.rootModalHost as? HostToastPresenting
            XCTAssertTrue(found === host)
        }
    }
}
