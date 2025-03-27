import UIKit


extension ToastPresentationViewController {

    func layout(presentation: Presentation, transitionValues: ToastTransitionValues) {
        let view: UIView = presentationView

        presentation.containerView.set(
            frame: view.convert(transitionValues.frame, to: self.view),
            transform: transitionValues.transform
        )
        presentation.containerView.alpha = transitionValues.alpha
        presentation.containerView.apply(
            shadow: transitionValues.shadow,
            corners: transitionValues.roundedCorners
        )
        transitionValues.roundedCorners.apply(toView: presentation.containerView.clippingView)
    }

    func transitionUpdate(
        presentation: Presentation,
        presentedValues: ToastTransitionValues
    ) {
        let animator = UIViewPropertyAnimator(animation: presentedValues.animation)

        updateTransitionUpdate(
            presentation: presentation,
            animator: animator,
            presentedValues: presentedValues
        )

        animator.addCompletion { [weak presentation, weak self] _ in
            guard let self,
                  let presentation
            else { return }

            presentation.state = .presented

            let behaviorContext = makeBehaviorContext()
            let behaviorPreferences = presentation.style.behaviorPreferences(for: behaviorContext)
            configureTimer(
                presentation: presentation,
                behaviorPreferences: behaviorPreferences
            )
        }

        presentation.state = .updating(animator)
        animator.startAnimation()
    }

    func updateTransitionUpdate(
        presentation: Presentation,
        animator: UIViewPropertyAnimator,
        presentedValues: ToastTransitionValues
    ) {
        animator.addAnimations { [weak presentation, weak self] in
            guard let self,
                  let presentation
            else { return }

            layout(
                presentation: presentation,
                transitionValues: presentedValues
            )
        }
    }

    func transitionIn(
        presentation: Presentation,
        presentedValues: ToastTransitionValues,
        style: ToastContainerPresentationStyle
    ) {
        let transitionContext = makeTransitionContext(presentedFrame: presentedValues.frame)
        let enterValues = style.enterTransitionValues(for: transitionContext)

        layout(
            presentation: presentation,
            transitionValues: enterValues
        )

        let animator = UIViewPropertyAnimator(animation: enterValues.animation)

        updateTransitionIn(
            presentation: presentation,
            animator: animator,
            presentedValues: presentedValues,
            style: style
        )

        animator.addCompletion { [weak presentation, weak self] _ in
            guard let self,
                  let presentation
            else { return }

            presentation.state = .presented

            let behaviorContext = makeBehaviorContext()
            let behaviorPreferences = presentation.style.behaviorPreferences(for: behaviorContext)
            configureTimer(
                presentation: presentation,
                behaviorPreferences: behaviorPreferences
            )

            UIAccessibility.post(
                notification: .announcement,
                argument: presentation.accessibilityAnnouncement
            )

            feedbackGenerator.notificationOccurred(
                behaviorPreferences.presentationHaptic
            )
        }

        presentation.state = .entering(animator)
        animator.startAnimation()
    }

    func updateTransitionIn(
        presentation: Presentation,
        animator: UIViewPropertyAnimator,
        presentedValues: ToastTransitionValues,
        style: ToastContainerPresentationStyle
    ) {
        animator.addAnimations { [weak presentation, weak self] in
            guard let self,
                  let presentation
            else { return }

            layout(
                presentation: presentation,
                transitionValues: presentedValues
            )
        }
    }

    func transitionOut(
        presentation: Presentation,
        exitValues: ToastTransitionValues,
        presentedValues: ToastTransitionValues,
        completion: (() -> Void)? = nil
    ) {
        let animator = UIViewPropertyAnimator(animation: exitValues.animation)

        animator.addAnimations { [weak presentation, weak self] in
            guard let self,
                  let presentation
            else { return }

            layout(
                presentation: presentation,
                transitionValues: exitValues
            )
        }

        animator.addCompletion { [weak self, weak presentation] _ in
            defer { completion?() }

            guard
                let self,
                let presentation
            else { return }

            let viewController = presentation.viewController

            if viewController.parent != nil {
                viewController.willMove(toParent: nil)
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()
            }

            presentation.containerView.removeFromSuperview()

            presentation.autoDismissTimer?.invalidate()

            guard let index = presentations.index(of: viewController) else { return }

            presentations.remove(at: index)
        }

        presentation.state = .exiting(animator)
        animator.startAnimation()
    }
}
