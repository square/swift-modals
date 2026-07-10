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
        var screen: UIViewController? = UIViewController()
        weak var weakScreen: UIViewController?
        weakScreen = screen
        content.addChild(try XCTUnwrap(screen))
        content.view.addSubview(try XCTUnwrap(screen).view)
        try XCTUnwrap(screen).didMove(toParent: content)

        let host = ModalHostContainerViewController(content: content)

        // Resolve the host from the triggering view controller, as a consumer would, and retain
        // the lifetime outside it — the toast's presentation must not depend on the trigger.
        let resolvedHost = try XCTUnwrap(screen?.rootModalHost as? HostToastPresenting)
        let lifetime = resolvedHost.contentToastPresenter.present(
            UIViewController(),
            style: .init(ToastPresentationStyleFixture()),
            accessibilityAnnouncement: "Toast."
        )

        // Remove the view controller that triggered the toast, as a navigation pop would.
        screen?.willMove(toParent: nil)
        screen?.view.removeFromSuperview()
        screen?.removeFromParent()
        screen = nil

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

    func test_removing_nested_host_clears_forwarded_toast_from_ancestor() {
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
            XCTAssertTrue(outerHost.toastPresentation.hasVisiblePresentations)

            innerHost.willMove(toParent: nil)
            innerHost.view.removeFromSuperview()
            innerHost.removeFromParent()
            outerHost.view.layoutIfNeeded()

            XCTAssertEqual(innerContent.aggregateModals().toasts.count, 1)
            XCTAssertTrue(
                outerHost.toastPresentation.presentedViewControllers.isEmpty,
                "The outer host must remove the stale forwarded toast when the inner host detaches."
            )
        }
    }

    func test_attaching_nested_host_forwards_existing_toast_to_ancestor() {
        let innerContent = UIViewController()
        let innerHost = ModalHostContainerViewController(content: innerContent)
        let outerContent = UIViewController()
        let outerHost = ModalHostContainerViewController(content: outerContent)

        let lifetime = innerHost.contentToastPresenter.present(
            UIViewController(),
            style: .init(ToastPresentationStyleFixture()),
            accessibilityAnnouncement: "Toast."
        )
        defer { lifetime.dismiss() }

        show(vc: outerHost) { outerHost in
            XCTAssertTrue(outerHost.toastPresentation.presentedViewControllers.isEmpty)

            outerContent.addChild(innerHost)
            outerContent.view.addSubview(innerHost.view)
            innerHost.didMove(toParent: outerContent)
            outerHost.view.layoutIfNeeded()

            XCTAssertTrue(innerHost.toastPresentation.presentedViewControllers.isEmpty)
            XCTAssertEqual(outerHost.toastPresentation.presentedViewControllers.count, 1)
        }
    }

    func test_stopping_passthrough_moves_toast_from_ancestor_to_nested_host() {
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
            XCTAssertFalse(innerHost.toastPresentation.hasVisiblePresentations)
            XCTAssertTrue(outerHost.toastPresentation.hasVisiblePresentations)

            innerHost.presentationFilter = nil
            innerHost.view.layoutIfNeeded()
            outerHost.view.layoutIfNeeded()

            XCTAssertTrue(innerHost.toastPresentation.hasVisiblePresentations)
            XCTAssertTrue(
                outerHost.toastPresentation.presentedViewControllers.isEmpty,
                "The outer host must remove the stale forwarded toast when passthrough stops."
            )
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
