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
    func `A horizontal safe area change cancels a modal interaction with old geometry`() throws {
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.view.frame = bounds
        let container = SafeAreaView(frame: bounds)
        subject.ancestorPresentationView = container
        let modal = UIViewController()
        subject.update(modals: [presentable(modal)])
        subject.view.frame = bounds
        subject.view.layoutIfNeeded()
        let presentation = try #require(subject.topmostPresentation)
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            modal.view.alpha = 0
        }
        animator.startAnimation()
        animator.pauseAnimation()
        presentation.transitionState = .interactiveDismiss(animator)

        container.reportedInsets = Self.horizontalInsets[0]
        subject.view.setNeedsLayout()
        subject.view.layoutIfNeeded()

        #expect(!presentation.transitionState.isInteracting)
        #expect(presentation.transitionState.animator == nil)
        #expect(animator.state != .active)
        #expect(subject.presentedViewControllers == [modal])
    }

    @Test
    func `Toast transform is applied to each style resolved from the environment`() {
        let previous = ToastPresentationViewController.containerStyleTransform
        defer { ToastPresentationViewController.containerStyleTransform = previous }
        let original = Recorder()
        let transformed = Recorder()
        var inputs = 0
        ToastPresentationViewController.containerStyleTransform = { style in
            #expect((style as? RecordingToastStyle)?.recorder === original)
            inputs += 1
            return RecordingToastStyle(recorder: transformed)
        }
        let subject = ToastPresentationViewController(styleProvider: .init(RecordingToastStyle(recorder: original)))
        subject.update(toasts: [toast()], safeAreaAnchors: [])
        subject.view.frame = bounds
        subject.view.layoutIfNeeded()
        #expect(inputs > 0)
        #expect(transformed.toastContexts.isEmpty == false)
        #expect(original.toastContexts.isEmpty)
        let previousCount = inputs
        subject.apply(environment: .empty)
        #expect(inputs == previousCount + 1)
    }

    @Test
    func `Toast safe area changes use its ancestor presentation view at a constant size`() {
        let recorder = Recorder()
        let subject = ToastPresentationViewController(styleProvider: .init(RecordingToastStyle(recorder: recorder)))
        let container = SafeAreaView(frame: bounds)
        subject.ancestorPresentationView = container
        let toast = toast()
        subject.update(toasts: [toast], safeAreaAnchors: [])
        subject.view.frame = bounds
        subject.view.layoutIfNeeded()

        for insets in Self.horizontalInsets + [.zero] {
            recorder.toastContexts = []
            container.reportedInsets = insets
            subject.view.setNeedsLayout()
            subject.view.layoutIfNeeded()
            #expect(recorder.toastContexts.last?.safeAreaInsets == insets)
            let frame = toast.viewController.view.convert(toast.viewController.view.bounds, to: subject.view)
            #expect(frame == bounds.inset(by: insets))
            #expect(subject.view.safeAreaInsets == .zero)
        }
    }

    @Test
    func `Vertical safe area changes preserve a toast timer`() throws {
        let recorder = Recorder()
        let subject = ToastPresentationViewController(styleProvider: .init(RecordingToastStyle(recorder: recorder)))
        let container = SafeAreaView(frame: bounds)
        subject.ancestorPresentationView = container
        subject.update(toasts: [toast(timedDismiss: .after(duration: 60, onDismiss: {}))], safeAreaAnchors: [])
        subject.view.frame = bounds
        subject.view.layoutIfNeeded()
        let timer = try #require(subject.presentations.first?.autoDismissTimer)
        recorder.toastContexts = []

        container.reportedInsets.top = 40
        subject.viewSafeAreaInsetsDidChange()
        subject.view.setNeedsLayout()
        subject.view.layoutIfNeeded()
        #expect(recorder.toastContexts.isEmpty)
        #expect(subject.presentations.first?.autoDismissTimer === timer)
    }

    private var bounds: CGRect { CGRect(x: 0, y: 0, width: 400, height: 800) }

    private nonisolated static let horizontalInsets: [UIEdgeInsets] = [
        UIEdgeInsets(top: 0, left: 84, bottom: 0, right: 0),
        UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 84),
    ]

    private func presentable(_ controller: UIViewController, style: ModalPresentationStyle = TestFullScreenStyle()) -> PresentableModal {
        PresentableModal(viewController: controller, presentationStyle: style, info: .empty(), onDidPresent: nil)
    }

    private func toast(timedDismiss: ToastBehaviorPreferences.TimedDismissBehavior = .disabled) -> PresentableToast {
        PresentableToast(
            viewController: UIViewController(),
            presentationStyle: ToastStyle(timedDismiss: timedDismiss),
            accessibilityAnnouncement: "Toast"
        )
    }
}

private final class SafeAreaView: UIView {
    var reportedInsets: UIEdgeInsets = .zero
    override var safeAreaInsets: UIEdgeInsets { reportedInsets }
}

private final class Recorder {
    var modalContexts: [ModalPresentationContext] = []
    var toastContexts: [ToastDisplayContext] = []
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

private struct RecordingToastStyle: ToastContainerPresentationStyle {
    let recorder: Recorder

    func displayValues(for context: ToastDisplayContext) -> ToastDisplayValues {
        recorder.toastContexts.append(context)
        let frame = CGRect(origin: .zero, size: context.containerSize).inset(by: context.safeAreaInsets)
        return ToastDisplayValues(presentedValues: context.preheatValues.map { _ in .init(frame: frame) })
    }

    func preheatValues(for context: ToastPreheatContext) -> ToastPreheatValues { .init(size: context.containerSize) }
    func enterTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues { .init(
        frame: context.displayFrame
    ) }
    func exitTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues { .init(
        frame: context.displayFrame
    ) }
    func reverseTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues { .init(
        frame: context.displayFrame
    ) }
    func interactiveExitTransitionValues(for context: ToastInteractiveExitContext) -> ToastTransitionValues { .init(
        frame: context.presentedFrame
    ) }
    func isEqual(to other: ToastContainerPresentationStyle) -> Bool { (other as? Self)?.recorder === recorder }
}

private struct ToastStyle: ToastPresentationStyle {
    var timedDismiss: ToastBehaviorPreferences.TimedDismissBehavior

    func behaviorPreferences(for context: ToastBehaviorContext) -> ToastBehaviorPreferences {
        ToastBehaviorPreferences(presentationHaptic: .success, timedDismiss: timedDismiss, interactiveDismiss: .disabled)
    }
}
