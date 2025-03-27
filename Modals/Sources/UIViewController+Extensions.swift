import UIKit

extension UIViewController {
    /// Calls the appropriate combination of `beginAppearanceTransition` and
    /// `endAppearanceTransition` methods to transition this view controller from `start` to `end`
    /// visibility states.
    func callAppearanceTransitions(
        from start: Visibility,
        to end: Visibility,
        animated: Bool
    ) {
        func willAppear() {
            beginAppearanceTransition(true, animated: animated)
        }
        func didAppear() {
            endAppearanceTransition()
        }
        func willDisappear() {
            beginAppearanceTransition(false, animated: animated)
        }
        func didDisappear() {
            endAppearanceTransition()
        }

        switch (start, end) {
        case (.appearing, .appearing):
            break
        case (.appearing, .appeared):
            didAppear()
        case (.appearing, .disappearing):
            willDisappear()
        case (.appearing, .disappeared):
            willDisappear()
            didDisappear()
        case (.appeared, .appearing):
            willDisappear()
            willAppear()
        case (.appeared, .appeared):
            break
        case (.appeared, .disappearing):
            willDisappear()
        case (.appeared, .disappeared):
            willDisappear()
            didDisappear()
        case (.disappearing, .appeared):
            willAppear()
            didAppear()
        case (.disappearing, .appearing):
            willAppear()
        case (.disappearing, .disappearing):
            break
        case (.disappearing, .disappeared):
            didDisappear()
        case (.disappeared, .appearing):
            willAppear()
        case (.disappeared, .appeared):
            willAppear()
            didAppear()
        case (.disappeared, .disappearing):
            willAppear()
            willDisappear()
        case (.disappeared, .disappeared):
            break
        }
    }
}
