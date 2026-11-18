import Testing
import UIKit
@_spi(ModalsImplementation) @testable import Modals

@Suite(.serialized) @MainActor
struct PresentationLayoutTests {
    @Test
    func `Modal transform receives the original style on presentation and update`() throws {
        let previous = ModalPresentationViewController.presentationStyleTransform
        defer { ModalPresentationViewController.presentationStyleTransform = previous }
        var inputs: [ModalPresentationStyle] = []
        let recorder = Recorder()
        ModalPresentationViewController.presentationStyleTransform = { style in
            inputs.append(style)
            return RecordingModalStyle(recorder: recorder, usesSafeArea: true)
        }
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.view.frame = bounds
        let modal = UIViewController()
        let presented = presentable(modal)
        subject.update(modals: [presented])
        subject.view.frame = bounds
        subject.view.layoutIfNeeded()

        #expect(inputs.count == 1)
        #expect(inputs.allSatisfy { $0 is TestFullScreenStyle })
        #expect(recorder.behaviorCalls > 0)
        #expect(recorder.modalContexts.isEmpty == false)
        #expect(recorder.enterCalls > 0)

        subject.update(modals: [presented])
        #expect(inputs.count == 2)
        #expect(inputs.allSatisfy { $0 is TestFullScreenStyle })

        subject.update(modals: [])
        #expect(recorder.exitCalls > 0)
    }

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
        let previous = ModalPresentationViewController.presentationStyleTransform
        defer { ModalPresentationViewController.presentationStyleTransform = previous }
        ModalPresentationViewController.presentationStyleTransform = { $0 }
        let recorder = Recorder()
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.view.frame = bounds
        let container = SafeAreaView(frame: bounds)
        subject.ancestorPresentationView = container
        let modal = UIViewController()
        subject.update(modals: [presentable(modal, style: RecordingModalStyle(recorder: recorder, usesSafeArea: true))])
        subject.view.frame = bounds
        subject.view.layoutIfNeeded()

        for insets in Self.horizontalInsets + [.zero] {
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
    func `Without a transform a modal safe area change alone keeps the existing layout`() {
        let previous = ModalPresentationViewController.presentationStyleTransform
        defer { ModalPresentationViewController.presentationStyleTransform = previous }
        ModalPresentationViewController.presentationStyleTransform = nil
        let recorder = Recorder()
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.view.frame = bounds
        let container = SafeAreaView(frame: bounds)
        subject.ancestorPresentationView = container
        let modal = UIViewController()
        subject.update(modals: [presentable(modal, style: RecordingModalStyle(recorder: recorder, usesSafeArea: true))])
        subject.view.frame = bounds
        subject.view.layoutIfNeeded()
        recorder.modalContexts = []

        container.reportedInsets = Self.horizontalInsets[0]
        subject.viewSafeAreaInsetsDidChange()
        subject.view.setNeedsLayout()
        subject.view.layoutIfNeeded()
        #expect(recorder.modalContexts.isEmpty)
        #expect(modal.view.convert(modal.view.bounds, to: subject.view) == bounds)
    }

    private var bounds: CGRect { CGRect(x: 0, y: 0, width: 400, height: 800) }

    private nonisolated static let horizontalInsets: [UIEdgeInsets] = [
        UIEdgeInsets(top: 0, left: 84, bottom: 0, right: 0),
        UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 84),
    ]

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
    var behaviorCalls = 0
    var enterCalls = 0
    var exitCalls = 0
    var contentInsets: UIEdgeInsets = .zero
}

private struct RecordingModalStyle: ModalPresentationStyle {
    let recorder: Recorder
    var usesSafeArea = false

    func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
        recorder.behaviorCalls += 1
        return ModalBehaviorPreferences(usesPreferredContentSize: false)
    }

    func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
        recorder.modalContexts.append(context)
        let frame = context.containerCoordinateSpace.bounds.inset(
            by: usesSafeArea ? context.containerSafeAreaInsets : .zero
        )
        return ModalDisplayValues(frame: frame, contentInsets: recorder.contentInsets, contentInsetsFillColor: .red)
    }

    func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        recorder.enterCalls += 1
        return ModalTransitionValues(
            frame: context.containerCoordinateSpace.bounds,
            animation: .curve(.linear, duration: 0)
        )
    }

    func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
        recorder.exitCalls += 1
        return ModalTransitionValues(
            frame: context.containerCoordinateSpace.bounds,
            animation: .curve(.linear, duration: 0)
        )
    }
}
