import Modals
import UIKit

/// A simple toast presentation style.
///
/// - Note: This style primarily describes the toast's behavior (e.g. auto-dismiss, interactive dismissal, etc.). See
///   ``ExampleToastContainerPresentationStyle`` for appearance
///   preferences.
///
public struct ExampleToastPresentationStyle: ToastPresentationStyle {

    public var onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public func behaviorPreferences(for context: ToastBehaviorContext) -> ToastBehaviorPreferences {
        ToastBehaviorPreferences(
            presentationHaptic: .warning,
            timedDismiss: .after(
                duration: 5,
                onDismiss: onDismiss
            ),
            interactiveDismiss: .swipeDown(onDismiss: onDismiss)
        )
    }
}
