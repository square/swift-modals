import Testing
import TestingSupport
import UIKit
@testable import Modals

@MainActor
@Suite(.serialized)
struct PresentationRootContentFramingTests {

    @Test
    func `A UIKit presented host frames content using its own horizontal safe area`() async throws {
        let bar = Bar.left
        let host = ModalHostContainerViewController(content: UIViewController())
        host.additionalSafeAreaInsets = bar.insets

        try await withPresentedController(host) {
            try withFramingHook(horizontalSafeAreaFraming) {
                host.modalPresentation.setNeedsPresentationLayout()
                host.view.layoutIfNeeded()

                let expectedFrame = host.view.bounds.inset(by: bar.insets)
                #expect(host.isPresentationRoot)
                #expect(host.view.safeAreaInsets.left == bar.insets.left)
                #expect(host.view.safeAreaInsets.right == bar.insets.right)
                #expect(host.content.view.convert(host.content.view.bounds, to: host.view) == expectedFrame)
                #expect(host.content.view.safeAreaInsets.left == 0)
                #expect(host.content.view.safeAreaInsets.right == 0)

                let fill = try #require(contentFill(in: host))
                #expect(fill.frame == host.modalPresentation.view.bounds)
                #expect(fill.viewport == host.content.view.frame)
                #expect(hasVisibleFill(fill))
            }
        }
    }

    @Test
    func `A window root host does not apply presentation root framing`() {
        let host = ModalHostContainerViewController(content: UIViewController())
        host.additionalSafeAreaInsets = Bar.right.insets
        let window = TestWindow(root: host)
        defer { window.tearDown() }

        var callbackCount = 0
        withFramingHook({ _ in
            callbackCount += 1
            return .init(insets: Bar.right.insets, fillColor: .red)
        }) {
            host.modalPresentation.setNeedsPresentationLayout()
            host.view.layoutIfNeeded()

            #expect(!host.isPresentationRoot)
            #expect(callbackCount == 0)
            #expect(host.content.view.frame == host.modalPresentation.view.bounds)
            #expect(contentFill(in: host) == nil)
        }
    }

    @Test
    func `A modal in a framed presentation root retains the full host width and is inset once`() async throws {
        let bar = Bar.right
        let host = ModalHostContainerViewController(content: UIViewController())
        host.additionalSafeAreaInsets = bar.insets

        try await withPresentedController(host) {
            try withFramingHook(horizontalSafeAreaFraming) {
                host.modalPresentation.setNeedsPresentationLayout()
                host.view.layoutIfNeeded()

                let modal = UIViewController()
                let lifetime = host.content.modalPresenter.present(
                    modal,
                    style: .init(SafeAreaContentStyle())
                )
                defer { lifetime.dismiss() }
                host.view.layoutIfNeeded()

                let presentation = try #require(host.modalPresentation.topmostPresentation)
                let expectedContentFrame = host.view.bounds.inset(by: bar.insets)
                #expect(host.modalPresentation.view.frame == host.view.bounds)
                #expect(presentation.containerView.frame == host.view.bounds)
                #expect(presentation.presentationView.frame == host.view.bounds)
                #expect(host.content.view.convert(host.content.view.bounds, to: host.view) == expectedContentFrame)
                #expect(modal.view.convert(modal.view.bounds, to: host.view) == expectedContentFrame)
                #expect(modal.view.safeAreaInsets.left == 0)
                #expect(modal.view.safeAreaInsets.right == 0)
            }
        }
    }

    @Test
    func `A visible presentation root uses changes to the framing callback on its next layout`() async throws {
        let host = ModalHostContainerViewController(content: UIViewController())
        host.additionalSafeAreaInsets = Bar.right.insets

        try await withPresentedController(host) {
            var framing: ModalHostContainerViewController.ContentFraming? = .init(
                insets: Bar.right.insets,
                fillColor: .red
            )
            try withFramingHook({ _ in framing }) {
                host.modalPresentation.setNeedsPresentationLayout()
                host.view.layoutIfNeeded()
                #expect(host.content.view.frame == host.view.bounds.inset(by: Bar.right.insets))

                framing = .init(insets: Bar.left.insets, fillColor: .blue)
                host.view.setNeedsLayout()
                host.view.layoutIfNeeded()

                #expect(host.content.view.frame == host.view.bounds.inset(by: Bar.left.insets))
                let fill = try #require(contentFill(in: host))
                #expect(fill.fillColor == UIColor.blue)
                #expect(fill.viewport == host.content.view.frame)
                #expect(hasVisibleFill(fill))

                framing = nil
                host.view.setNeedsLayout()
                host.view.layoutIfNeeded()

                #expect(host.content.view.frame == host.modalPresentation.view.bounds)
                #expect(fill.fillColor == nil)
                #expect(!hasVisibleFill(fill))
            }
        }
    }

    private enum Bar {
        case left
        case right

        var insets: UIEdgeInsets {
            switch self {
            case .left: UIEdgeInsets(top: 0, left: 84, bottom: 0, right: 0)
            case .right: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 84)
            }
        }
    }

    private func horizontalSafeAreaFraming(
        for host: ModalHostContainerViewController
    ) -> ModalHostContainerViewController.ContentFraming? {
        let insets = host.view.safeAreaInsets
        return .init(
            insets: UIEdgeInsets(top: 0, left: insets.left, bottom: 0, right: insets.right),
            fillColor: .red
        )
    }

    private func withFramingHook(
        _ hook: @escaping @MainActor (ModalHostContainerViewController) -> ModalHostContainerViewController.ContentFraming?,
        _ body: () throws -> Void
    ) rethrows {
        let previousHook = ModalHostContainerViewController.presentationRootContentFraming
        let animationsEnabled = UIView.areAnimationsEnabled
        ModalHostContainerViewController.presentationRootContentFraming = hook
        UIView.setAnimationsEnabled(false)
        defer {
            ModalHostContainerViewController.presentationRootContentFraming = previousHook
            UIView.setAnimationsEnabled(animationsEnabled)
        }
        try body()
    }

    private func contentFill(in host: ModalHostContainerViewController) -> InsetFillView? {
        host.modalPresentation.view.subviews.compactMap { $0 as? InsetFillView }.first
    }

    private func hasVisibleFill(_ fill: InsetFillView) -> Bool {
        !fill.isHidden && fill.subviews.contains {
            !$0.isHidden && !$0.frame.isEmpty && $0.backgroundColor != nil
        }
    }

    private func withPresentedController(
        _ controller: UIViewController,
        _ body: () throws -> Void
    ) async rethrows {
        let presenter = UIViewController()
        let window = TestWindow(root: presenter)
        defer { window.tearDown() }
        controller.modalPresentationStyle = .overFullScreen

        await withCheckedContinuation { continuation in
            presenter.present(controller, animated: false) { continuation.resume() }
        }
        controller.view.layoutIfNeeded()

        do {
            try body()
        } catch {
            await dismiss(from: presenter)
            throw error
        }
        await dismiss(from: presenter)
    }

    private func dismiss(from presenter: UIViewController) async {
        await withCheckedContinuation { continuation in
            presenter.dismiss(animated: false) { continuation.resume() }
        }
    }

    @MainActor
    private final class TestWindow {
        let window: UIWindow

        init(root: UIViewController) {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
            window.rootViewController = root
            window.isHidden = false
            window.layoutIfNeeded()
        }

        func tearDown() {
            window.isHidden = true
            window.rootViewController = nil
        }
    }

    private struct SafeAreaContentStyle: ModalPresentationStyle {
        func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
            .init(usesPreferredContentSize: false)
        }

        func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
            .init(
                frame: MainActor.assumeIsolated { context.containerCoordinateSpace.bounds },
                contentInsets: UIEdgeInsets(
                    top: 0,
                    left: context.containerSafeAreaInsets.left,
                    bottom: 0,
                    right: context.containerSafeAreaInsets.right
                ),
                contentInsetsFillColor: .red
            )
        }

        func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
            .init(
                frame: MainActor.assumeIsolated { context.containerCoordinateSpace.bounds },
                animation: .curve(.linear, duration: 0)
            )
        }

        func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
            .init(
                frame: MainActor.assumeIsolated { context.containerCoordinateSpace.bounds },
                animation: .curve(.linear, duration: 0)
            )
        }
    }
}
