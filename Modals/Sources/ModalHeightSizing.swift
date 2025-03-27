import CoreGraphics
import Foundation

/// The sizing behavior for the height of the modal.
public enum ModalHeightSizing: Equatable {
    /// The modal will be sized relative to its preferred content size. If the content size
    /// is larger than the available space, it will be rendered at a maximum height.
    /// This is the default option, and preferred for modals with a single screen.
    case content

    /// The modal will be full height (less the styling insets) regardless of the preferred
    /// content size. This option should be used if your modal has a flow with multiple steps,
    /// since they might vary in height.
    case fixed

    /// Returns the height to use based on the provided preferred content size and maximum height.
    ///
    /// If the modal height behavior is relative to content and we have a preferred content size,
    /// use the preferred content size; otherwise, use the fixed behavior and use the maximum height.
    public func height(
        for preferredContentSize: ModalPresentationContext.PreferredContentSize,
        maximumHeight: CGFloat
    ) -> CGFloat {
        switch (self, preferredContentSize) {
        case (.content, .known(let size)):
            min(size.height, maximumHeight)
        default:
            maximumHeight
        }
    }

    /// Whether or not this modal height sizing behavior requires a `preferredContentSize` to be calculated.
    public var usesPreferredContentSize: Bool {
        switch self {
        case .content:
            true

        case .fixed:
            false
        }
    }
}
