import UIKit



extension ToastPresentationViewController {

    private var containerSize: CGSize {
        presentationView.frame.size
    }

    func makeDisplayContext(presentations: [Presentation]) -> ToastDisplayContext {
        ToastDisplayContext(
            containerSize: containerSize,
            safeAreaInsets: adjustedSafeAreaInsets,
            scale: view.layer.contentsScale,
            preheatValues: presentations.map { presentation in
                .init(preferredContentSize: presentation.viewController.preferredContentSize)
            }
        )
    }

    func makeTransitionContext(presentedFrame: CGRect) -> ToastTransitionContext {
        ToastTransitionContext(
            displayFrame: presentedFrame,
            containerSize: containerSize,
            safeAreaInsets: adjustedSafeAreaInsets,
            scale: view.layer.contentsScale
        )
    }

    func makeInteractiveExitContext(
        presentedFrame: CGRect,
        velocity: CGVector
    ) -> ToastInteractiveExitContext {
        ToastInteractiveExitContext(
            presentedFrame: presentedFrame,
            containerSize: containerSize,
            safeAreaInsets: adjustedSafeAreaInsets,
            scale: view.layer.contentsScale,
            velocity: velocity
        )
    }

    func makeBehaviorContext() -> ToastBehaviorContext {
        ToastBehaviorContext()
    }

    func makePreheatContext() -> ToastPreheatContext {
        ToastPreheatContext(
            containerSize: containerSize,
            safeAreaInsets: adjustedSafeAreaInsets
        )
    }

    private var adjustedSafeAreaInsets: UIEdgeInsets {
        let view: UIView = presentationView
        var safeAreaInsets = max(view.safeAreaInsets, safeAreaAnchorInsets)

        guard let keyboardFrame = keyboardObserver.currentFrame(in: view) else {
            return safeAreaInsets
        }

        switch keyboardFrame {
        case .nonOverlapping:
            return safeAreaInsets

        case .overlapping(frame: let overlappingFrame):
            guard overlappingFrame.maxY >= view.frame.maxY else {
                // Keyboard is likely floating—don't adjust insets.
                // TODO: Better handle fluid layout around floating keyboard
                return safeAreaInsets
            }

            let keyboardOffset = view.frame.maxY - overlappingFrame.minY
            safeAreaInsets.bottom = max(safeAreaInsets.bottom, keyboardOffset)

            return safeAreaInsets
        }
    }
}


private func max(_ lhs: UIEdgeInsets, _ rhs: UIEdgeInsets) -> UIEdgeInsets {
    .init(
        top: max(lhs.top, rhs.top),
        left: max(lhs.left, rhs.left),
        bottom: max(lhs.bottom, rhs.bottom),
        right: max(lhs.right, rhs.right)
    )
}
