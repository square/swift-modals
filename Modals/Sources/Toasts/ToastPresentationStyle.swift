import UIKit


/// The presentation style to use for an individual toast.
///
/// This style describes the behavior preferences for the toast (e.g. auto-dismiss, interactive dismissal, etc.)—to
/// adjust appearance preferences, see [ToastContainerPresentationStyle](x-source-tag://ToastContainerPresentationStyle).
///
public protocol ToastPresentationStyle {

    /// The behavior preferences of this toast presentation.
    ///
    func behaviorPreferences(for context: ToastBehaviorContext) -> ToastBehaviorPreferences
}
