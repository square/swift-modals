import Testing
import UIKit
@_spi(ModalsImplementation) @testable import Modals

@Suite(.serialized) @MainActor
struct PresentationLayoutTests {
    @Test
    func `Modal content insets change without changing its frame or overlay`() throws {
        let insets = Self.horizontalInsets[0]
        let recorder = Recorder()
        recorder.contentInsets = insets
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.view.frame = bounds
        let modal = UIViewController()
        subject.update(modals: [presentable(modal, style: RecordingModalStyle(recorder: recorder))])
        subject.view.frame = bounds
        subject.view.layoutIfNeeded()
        let clipping = try #require(modal.view.superview as? ClippingView)
        let container = try #require(subject.view.subviews.compactMap {
            $0 as? ModalPresentationViewController.ContainerView
        }.first)
        #expect(container.shadowView.frame == bounds)
        #expect(container.overlayView.frame == bounds)
        #expect(modal.view.frame == bounds.inset(by: insets))

        recorder.contentInsets = .zero
        subject.setNeedsPresentationLayout()
        subject.view.layoutIfNeeded()
        #expect(modal.view.frame == bounds)
        #expect(clipping.contentInsets == .zero)
        #expect(container.shadowView.frame == bounds)
    }

    @Test
    func `Modal safe area changes move a presentation without a size change`() {
        let recorder = Recorder()
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.view.frame = bounds
        let container = SafeAreaView(frame: bounds)
        subject.ancestorPresentationView = container
        let modal = UIViewController()
        subject.update(modals: [presentable(modal, style: RecordingModalStyle(recorder: recorder, usesSafeArea: true))])
        subject.view.frame = bounds
        subject.view.layoutIfNeeded()

        for insets in [Self.verticalInsets] + Self.horizontalInsets + [.zero] {
            recorder.modalContexts = []
            container.reportedInsets = insets
            subject.view.setNeedsLayout()
            subject.view.layoutIfNeeded()
            #expect(recorder.modalContexts.last?.containerSafeAreaInsets == insets)
            #expect(modal.view.convert(modal.view.bounds, to: subject.view) == bounds.inset(by: insets))
            #expect(subject.view.bounds == bounds)
        }
    }

    @Test
    func `An unchanged safe area keeps the existing layout`() {
        let recorder = Recorder()
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.view.frame = bounds
        let container = SafeAreaView(frame: bounds)
        subject.ancestorPresentationView = container
        let modal = UIViewController()
        subject.update(modals: [presentable(modal, style: RecordingModalStyle(recorder: recorder, usesSafeArea: true))])
        subject.view.frame = bounds
        container.reportedInsets = Self.verticalInsets
        subject.view.setNeedsLayout()
        subject.view.layoutIfNeeded()
        recorder.modalContexts = []

        subject.viewSafeAreaInsetsDidChange()
        subject.view.setNeedsLayout()
        subject.view.layoutIfNeeded()
        #expect(recorder.modalContexts.isEmpty)
        #expect(modal.view.convert(modal.view.bounds, to: subject.view) == bounds.inset(by: Self.verticalInsets))
    }

    @Test(.timeLimit(.minutes(1)))
    func `A style replaced by an update repaints a presented modal without a size change`() async throws {
        let recorder = Recorder()
        recorder.contentInsets = Self.horizontalInsets[0]
        let subject = ModalPresentationViewController(content: UIViewController())
        // The enter animation only completes in a visible window.
        let window = UIWindow(frame: bounds)
        window.rootViewController = subject
        window.isHidden = false
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let modal = UIViewController()
        await withCheckedContinuation { continuation in
            subject.update(modals: [PresentableModal(
                viewController: modal,
                presentationStyle: RecordingModalStyle(recorder: recorder),
                info: .empty(),
                onDidPresent: { continuation.resume() }
            )])
            subject.view.layoutIfNeeded()
        }

        let style = RecordingModalStyle(recorder: recorder, fillColor: Self.darkFill, overlayColor: Self.darkOverlay)
        subject.update(modals: [presentable(modal, style: style)])
        subject.view.layoutIfNeeded()

        let container = try #require(subject.view.subviews.compactMap {
            $0 as? ModalPresentationViewController.ContainerView
        }.first)
        let fill = try #require(modal.view.superview?.subviews.compactMap { $0 as? InsetFillView }.first)
        // The strips, not the fill view's stored color, are what paint the fill.
        #expect(fill.subviews.filter { !$0.frame.isEmpty }.map(\.backgroundColor) == [Self.darkFill])
        #expect(container.overlayView.backgroundColor == Self.darkOverlay)
    }

    private var bounds: CGRect { CGRect(x: 0, y: 0, width: 400, height: 800) }

    private static let darkFill = UIColor(white: 0.1, alpha: 1)
    private static let darkOverlay = UIColor(white: 0, alpha: 0.7)

    private nonisolated static let horizontalInsets: [UIEdgeInsets] = [
        UIEdgeInsets(top: 0, left: 84, bottom: 0, right: 0),
        UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 84),
    ]

    private nonisolated static let verticalInsets = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)

    private func presentable(_ controller: UIViewController, style: ModalPresentationStyle = TestFullScreenStyle()) -> PresentableModal {
        PresentableModal(viewController: controller, presentationStyle: style, info: .empty(), onDidPresent: nil)
    }
}

private final class SafeAreaView: UIView {
    var reportedInsets: UIEdgeInsets = .zero
    override var safeAreaInsets: UIEdgeInsets { reportedInsets }
}

private final class Recorder {
    var modalContexts: [ModalPresentationContext] = []
    var contentInsets: UIEdgeInsets = .zero
}

private struct RecordingModalStyle: ModalPresentationStyle {
    let recorder: Recorder
    var usesSafeArea = false
    var fillColor: UIColor = .red
    var overlayColor: UIColor = .black

    func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
        ModalBehaviorPreferences(usesPreferredContentSize: false)
    }

    func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
        recorder.modalContexts.append(context)
        let frame = context.containerCoordinateSpace.bounds.inset(
            by: usesSafeArea ? context.containerSafeAreaInsets : .zero
        )
        return ModalDisplayValues(
            frame: frame,
            overlayColor: overlayColor,
            contentInsets: recorder.contentInsets,
            contentInsetsFillColor: fillColor
        )
    }

    func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(
            frame: context.containerCoordinateSpace.bounds,
            animation: .curve(.linear, duration: 0)
        )
    }

    func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        ModalTransitionValues(
            frame: context.containerCoordinateSpace.bounds,
            animation: .curve(.linear, duration: 0)
        )
    }
}
