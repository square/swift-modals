import UIKit


/// The display values for all presented toasts.
///
/// These values are used by the toast presentation system to position toasts, perform transitions, and add additional
/// chrome (e.g. shadows).
///
public struct ToastDisplayValues {

    /// An array of transition values for each of the presented toasts.
    ///
    /// This array is ordered in the order that toasts are presented in (oldest first).
    ///
    public var presentedValues: [ToastTransitionValues]

    /// Creates display values.
    ///
    public init(presentedValues: [ToastTransitionValues]) {
        self.presentedValues = presentedValues
    }
}
