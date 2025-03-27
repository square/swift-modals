import Foundation

/// The sizing behavior for the width of a modal.
public enum ModalWidthSizing {
    /// The default width, from the stylesheet. This is the default option
    case `default`
    /// A dynamic width, based off the `ModalPresentationContext`. If the width is larger than the
    /// available space, it will be rendered to fill the available space
    case dynamic((ModalPresentationContext) -> (CGFloat))

    /// An explicit width, in pixels. If the width is larger than the available space, it will be
    /// rendered to fill the available space
    public static func explicit(_ width: CGFloat) -> Self {
        .dynamic { _ in width }
    }
}
