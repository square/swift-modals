import Foundation
import UIKit


/// Toast behavior preferences are used by the toast presentation system to configure certain behaviors, such as whether
/// the toast should be auto-dismissed after a delay or support interactive dismissal.
///
public struct ToastBehaviorPreferences {

    /// The timed auto-dismiss behavior.
    ///
    public enum TimedDismissBehavior {

        /// Disables the timed auto-dismiss behavior.
        ///
        case disabled

        /// Dismisses the toast after the provided duration.
        ///
        case after(duration: TimeInterval, onDismiss: () -> Void)
    }

    /// The interactive dismissal behavior.
    ///
    public enum InteractiveDismissBehavior {

        /// Disables interactive dismissal.
        ///
        case disabled

        /// Dismisses the toast when the toast is swiped downward.
        ///
        /// Calls the provided closure when the dismiss animation completes. The toast should be dismissed (removed from
        /// aggregation) when this closure is called.
        ///
        case swipeDown(onDismiss: () -> Void)
    }

    /// The haptic feedback that should be performed when the toast is presented.
    ///
    public var presentationHaptic: UINotificationFeedbackGenerator.FeedbackType

    /// The timed auto-dismiss behavior.
    ///
    public var timedDismiss: TimedDismissBehavior

    /// The interactive dismissal behavior.
    ///
    public var interactiveDismiss: InteractiveDismissBehavior

    /// Creates toast behavior preferences.
    ///
    public init(
        presentationHaptic: UINotificationFeedbackGenerator.FeedbackType,
        timedDismiss: TimedDismissBehavior,
        interactiveDismiss: InteractiveDismissBehavior
    ) {
        self.presentationHaptic = presentationHaptic
        self.timedDismiss = timedDismiss
        self.interactiveDismiss = interactiveDismiss
    }
}
