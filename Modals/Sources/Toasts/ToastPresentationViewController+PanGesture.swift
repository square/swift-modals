import UIKit


extension ToastPresentationViewController {

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard
            let style,
            let (index, presentation) = presentations.presentation(for: gesture)
        else {
            return
        }

        view.bringSubviewToFront(presentation.containerView)

        presentation.autoDismissTimer?.invalidate()
        presentation.autoDismissTimer = nil

        let displayContext = makeDisplayContext(presentations: presentations)
        let displayValues = style.displayValues(for: displayContext)
        let presentedValues = displayValues.presentedValues[index]
        let interactiveExitContext = makeInteractiveExitContext(
            presentedFrame: presentedValues.frame,
            velocity: CGVector(dx: 0, dy: 1)
        )
        let exitValues = style.interactiveExitTransitionValues(for: interactiveExitContext)

        let initialVerticalOffset = presentation.state.interaction?.initialVerticalOffset ?? presentedValues.frame.minY
        let offset = gesture.translation(in: view).y
        let isInverse = offset < 0
        let dismissDistance = exitValues.frame.minY - initialVerticalOffset

        let fractionComplete: CGFloat = if dismissDistance > 0 {
            min(abs(offset) / dismissDistance, 1)
        } else {
            0
        }

        func setUpDismissInteraction() {
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

            presentation.state = .interactiveDismiss(.init(
                animator: animator,
                initialVerticalOffset: initialVerticalOffset
            ))
            animator.fractionComplete = fractionComplete
        }

        func setUpInverseInteraction() {
            // Adjust the presentation context so if a toast below is removed during interaction, the offset is still
            // relative to the initial position.
            var transitionContext = makeTransitionContext(presentedFrame: presentedValues.frame)
            transitionContext.displayFrame.origin.y = initialVerticalOffset
            let reverseValues = style.reverseTransitionValues(for: transitionContext)

            let animator = UIViewPropertyAnimator(animation: reverseValues.animation)

            animator.addAnimations { [weak presentation, weak self] in
                guard let self,
                      let presentation
                else { return }

                layout(
                    presentation: presentation,
                    transitionValues: reverseValues
                )
            }

            // Ensure we update our state *before* updating the animation, since starting the
            // animation will cause things to lay out
            presentation.state = .interactiveInverse(.init(
                animator: animator,
                initialVerticalOffset: initialVerticalOffset
            ))
            animator.scrubsLinearly = false
            animator.fractionComplete = fractionComplete
        }

        switch gesture.state {
        case .began,
             .changed:
            switch presentation.state {
            case .interactiveDismiss(let interaction):
                if isInverse {
                    interaction.animator.stopAnimationIfNeeded(withoutFinishing: false)
                    interaction.animator.finishAnimation(at: .start)
                    setUpInverseInteraction()
                } else {
                    interaction.animator.fractionComplete = fractionComplete
                }

            case .interactiveInverse(let interaction):
                if isInverse {
                    interaction.animator.fractionComplete = fractionComplete
                } else {
                    interaction.animator.stopAnimationIfNeeded(withoutFinishing: false)
                    interaction.animator.finishAnimation(at: .start)
                    setUpDismissInteraction()
                }

            case .presented:
                if isInverse {
                    setUpInverseInteraction()
                } else {
                    setUpDismissInteraction()
                }

            case .pending,
                 .updating,
                 .entering,
                 .transitioningSize,
                 .pendingExit,
                 .exiting:
                break
            }

        case .ended, .cancelled:
            switch presentation.state {
            case .interactiveDismiss(let interaction),
                 .interactiveInverse(let interaction):

                interaction.animator.stopAnimationIfNeeded(withoutFinishing: true)

                let velocity = gesture.velocity(in: presentation.containerView)
                let shouldDismissBasedOnProjection = projectShouldDismiss(
                    for: presentation,
                    with: velocity,
                    destinationFrame: exitValues.frame
                )

                let shouldDismiss = shouldDismissBasedOnProjection
                    && gesture.state == .ended

                let behaviorContext = makeBehaviorContext()
                let behaviorPreferences = presentation.style.behaviorPreferences(for: behaviorContext)

                if shouldDismiss,
                   case .swipeDown(let onDismiss) = behaviorPreferences.interactiveDismiss
                {
                    let distanceRemaining = dismissDistance - offset
                    let relativeVelocity = CGVector(
                        dx: velocity.x / distanceRemaining,
                        dy: velocity.y / distanceRemaining
                    )
                    let interactiveExitContext = makeInteractiveExitContext(
                        presentedFrame: presentedValues.frame,
                        velocity: relativeVelocity
                    )
                    let exitValues = style.interactiveExitTransitionValues(for: interactiveExitContext)
                    // We start the animation instead of waiting for the update so that we ensure a smooth transition
                    // even if there is a delay from the caller (e.g. asynchronous Workflow update).
                    // We don't need to remove the presentation ourselves—the toast-presenting consumer will need to
                    // remove the toast and update their list of Toasts.
                    transitionOut(
                        presentation: presentation,
                        exitValues: exitValues,
                        presentedValues: presentedValues,
                        completion: { [weak modalHost] in
                            onDismiss()
                            // If the toast wasn't removed ensure we update back to the presented state immediately.
                            modalHost?.setNeedsModalUpdate()
                        }
                    )
                } else {
                    transitionUpdate(
                        presentation: presentation,
                        presentedValues: presentedValues
                    )
                }

            case .pending,
                 .updating,
                 .entering,
                 .transitioningSize,
                 .pendingExit,
                 .exiting,
                 .presented:
                break
            }

        case .failed,
             .possible:
            break

        @unknown default:
            break
        }
    }

    private func projectShouldDismiss(
        for presentation: Presentation,
        with velocity: CGPoint,
        destinationFrame: CGRect
    ) -> Bool {
        let currentFrame = presentation.containerView.frame
        let projectedFrame = Dynamics.projectedFrame(from: currentFrame, initialVelocity: velocity)
        return projectedFrame.origin.y >= destinationFrame.origin.y
    }
}
