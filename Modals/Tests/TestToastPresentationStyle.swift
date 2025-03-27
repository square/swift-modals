import Modals
import UIKit

struct TestToastPresentationStyle: ToastPresentationStyle {
    var identifier: String? = nil
    var haptic: UINotificationFeedbackGenerator.FeedbackType = .warning

    func behaviorPreferences(for context: ToastBehaviorContext) -> ToastBehaviorPreferences {
        ToastBehaviorPreferences(
            presentationHaptic: haptic,
            timedDismiss: .after(duration: 1.2, onDismiss: {}),
            interactiveDismiss: .disabled
        )
    }
}
