import Modals
import UIKit


public struct ToastPresentationStyleFixture: ToastPresentationStyle {
    public var key: String
    public var haptic: UINotificationFeedbackGenerator.FeedbackType

    public init(key: String = "", haptic: UINotificationFeedbackGenerator.FeedbackType = .warning) {
        self.key = key
        self.haptic = haptic
    }

    public func behaviorPreferences(for context: ToastBehaviorContext) -> ToastBehaviorPreferences {
        .init(
            presentationHaptic: haptic,
            timedDismiss: .disabled,
            interactiveDismiss: .disabled
        )
    }
}
