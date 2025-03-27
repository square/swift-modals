import UIKit


/// Contextual information provided to a `ToastContainerPresentationStyle` when getting display values.
///
public struct ToastDisplayContext {

    /// Contains resolved preheat (a layout pass that resolves a `preferredContentSize`) values for each toast.
    ///
    public struct PreheatValues {

        /// The resolved `preferredContentSize` of the toast's backing view controller.
        ///
        public var preferredContentSize: CGSize

        /// Creates a new set of preheat values.
        ///
        public init(preferredContentSize: CGSize) {
            self.preferredContentSize = preferredContentSize
        }
    }

    /// The size of the presentation container.
    ///
    public var containerSize: CGSize

    /// The safe area insets of the container.
    ///
    /// - Note: This accounts for the keyboard frame when appropriate.
    ///
    public var safeAreaInsets: UIEdgeInsets

    /// The natural scale factor associated with the screen the toasts are presented in.
    ///
    public var scale: CGFloat

    /// A collection of preheat (a layout pass that resolves a `preferredContentSize`) values that represent each toast
    /// being presented.
    ///
    /// This array is ordered in the order that toasts are presented in (oldest first).
    ///
    public var preheatValues: [PreheatValues]

    /// Creates a new display context.
    ///
    public init(
        containerSize: CGSize,
        safeAreaInsets: UIEdgeInsets,
        scale: CGFloat,
        preheatValues: [PreheatValues]
    ) {
        self.containerSize = containerSize
        self.safeAreaInsets = safeAreaInsets
        self.scale = scale
        self.preheatValues = preheatValues
    }
}
