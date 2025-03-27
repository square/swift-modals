import UIKit

/// Contextual information provided to a `ModalPresentationStyle` when getting display preferences.
public struct ModalPreferenceContext {
    /// The viewport size.
    public var viewportSize: CGSize

    /// Create a preference context.
    public init(viewportSize: CGSize) {
        self.viewportSize = viewportSize
    }
}
