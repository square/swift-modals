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

    func test_toast_outlives_presenting_descendent() throws {
        let content = UIViewController()
        weak var weakScreen: UIViewController?
        let host = ModalHostContainerViewController(content: content)

        func presentFromDescendent() throws -> ModalLifetime {
            let screen = UIViewController()
            weakScreen = screen
            content.addChild(screen)
            content.view.addSubview(screen.view)
            screen.didMove(toParent: content)

            // Resolve the host from the triggering view controller, as a consumer would, and
            // return the lifetime to an owner outside it.
            let resolvedHost = try XCTUnwrap(screen.rootModalHost as? HostToastPresenting)
            let lifetime = resolvedHost.contentToastPresenter.present(
                UIViewController(),
                style: .init(ToastPresentationStyleFixture()),
                accessibilityAnnouncement: "Toast."
            )

            // Remove the view controller that triggered the toast, as a navigation pop would.
            screen.willMove(toParent: nil)
            screen.view.removeFromSuperview()
            screen.removeFromParent()

            return lifetime
        }

        let lifetime = try presentFromDescendent()

        XCTAssertNil(weakScreen)

        XCTAssertEqual(
            content.aggregateModals().toasts.count,
            1,
            "The toast should remain presented after the triggering view controller is removed."
        )

        show(vc: host) { host in
            XCTAssertTrue(host.toastPresentation.hasVisiblePresentations)

            lifetime.dismiss()
            host.view.layoutIfNeeded()

            XCTAssertTrue(host.toastPresentation.presentedViewControllers.isEmpty)
        }
    }

    func test_nested_host_forwards_toasts_to_ancestor_by_default() {
        let innerContent = UIViewController()
        let innerHost = ModalHostContainerViewController(content: innerContent)

        let outerContent = UIViewController()
        outerContent.addChild(innerHost)
        outerContent.view.addSubview(innerHost.view)
        innerHost.didMove(toParent: outerContent)

        let outerHost = ModalHostContainerViewController(content: outerContent)

        let lifetime = innerHost.contentToastPresenter.present(
            UIViewController(),
            style: .init(ToastPresentationStyleFixture()),
            accessibilityAnnouncement: "Toast."
        )
        defer { lifetime.dismiss() }

        show(vc: outerHost) { outerHost in
            innerHost.view.layoutIfNeeded()

            // The default pass-through-toasts filter forwards the toast to the ancestor host.
            XCTAssertFalse(innerHost.toastPresentation.hasVisiblePresentations)
            XCTAssertTrue(outerHost.toastPresentation.hasVisiblePresentations)
        }
    }

    func test_nested_host_presents_toasts_locally_when_not_passing_through() {
        let innerContent = UIViewController()
        let innerHost = ModalHostContainerViewController(
            content: innerContent,
            shouldPassthroughToasts: false
        )

        let outerContent = UIViewController()
        outerContent.addChild(innerHost)
        outerContent.view.addSubview(innerHost.view)
        innerHost.didMove(toParent: outerContent)

        let outerHost = ModalHostContainerViewController(content: outerContent)

        let lifetime = innerHost.contentToastPresenter.present(
            UIViewController(),
            style: .init(ToastPresentationStyleFixture()),
            accessibilityAnnouncement: "Toast."
        )
        defer { lifetime.dismiss() }

        show(vc: outerHost) { outerHost in
            innerHost.view.layoutIfNeeded()

            // Without the pass-through filter, the inner host displays its own toasts.
            XCTAssertTrue(innerHost.toastPresentation.hasVisiblePresentations)
            XCTAssertFalse(outerHost.toastPresentation.hasVisiblePresentations)
        }
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
