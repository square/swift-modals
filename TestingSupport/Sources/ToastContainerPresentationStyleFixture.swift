import Modals

struct ToastContainerPresentationStyleFixture: ToastContainerPresentationStyle {
    func displayValues(for context: ToastDisplayContext) -> ToastDisplayValues {
        .init(
            presentedValues: context.preheatValues.map {
                .init(
                    frame: .init(
                        origin: .zero,
                        size: $0.preferredContentSize
                    )
                )
            }
        )
    }

    func enterTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues {
        .init(frame: context.displayFrame)
    }

    func exitTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues {
        .init(frame: context.displayFrame)
    }

    func interactiveExitTransitionValues(for context: ToastInteractiveExitContext) -> ToastTransitionValues {
        .init(frame: context.presentedFrame)
    }

    func reverseTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues {
        .init(frame: context.displayFrame)
    }

    func preheatValues(for context: ToastPreheatContext) -> ToastPreheatValues {
        .init(size: context.containerSize)
    }

    func isEqual(to other: ToastContainerPresentationStyle) -> Bool {
        true
    }
}

extension ToastContainerPresentationStyleProvider {

    public static let fixture: Self = .init(ToastContainerPresentationStyleFixture())
}
