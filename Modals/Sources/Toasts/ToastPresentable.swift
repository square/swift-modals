import Foundation

/// This is a convenience for view controllers or screens to specify their own toast styles. Types
/// do not need to conform to this protocol to be presented as toasts, but this allows types to
/// provide a standard `ToastPresentationStyleProvider` to be presented with.
///
/// If your view controller or workflow screen has a standard toast presentation style, it can
/// conform to this protocol and return that style from the `presentationStyle` property so
/// consumers don't have to specify a style. In UIKit, `ToastPresenter` has a `present` method for
/// view controllers that conform to this protocol. In Workflows, `Toast` has an initializer that
/// takes in screens conforming to this protocol.
///
public protocol ToastPresentable {

    /// The text to announce using VoiceOver when the toast is displayed.
    ///
    var accessibilityAnnouncement: String { get }

    /// A provider that vends a `ToastPresentationStyle` from an `Environment`.
    ///
    var presentationStyle: ToastPresentationStyleProvider { get }
}
