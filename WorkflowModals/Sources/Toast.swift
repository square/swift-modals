import Modals
import WorkflowUI


public typealias AnyToast = Toast<AnyScreen>


/// Use this type to provide a key, toast presentation style, and accessibility announcement for content presented in a
/// [ToastContainer](x-source-tag://ToastContainer).
///
public struct Toast<Content> {
    /// The key is used to determine which toast are presented and dismissed when the modal
    /// container updates its screen. While they don't need to be unique, they must be stable
    /// or your toast will animate in and out when the screen updates.
    public var key: AnyHashable

    /// Provides a style for the toast based on the `ViewEnvironment` the screen is rendered in.
    public var style: ToastPresentationStyleProvider

    /// The content of the toast.
    public var content: Content

    /// The text that will be read aloud by VoiceOver when the toast is presented and VoiceOver is enabled.
    public var accessibilityAnnouncement: String

    /// Create a new toast.
    public init(
        key: some Hashable,
        style: ToastPresentationStyleProvider,
        content: Content,
        accessibilityAnnouncement: String
    ) {
        self.key = AnyHashable(key)
        self.style = style
        self.content = content
        self.accessibilityAnnouncement = accessibilityAnnouncement
    }

    /// Convenience init for creating a toast with a static presentation style.
    public init(
        key: some Hashable,
        style: ToastPresentationStyle,
        content: Content,
        accessibilityAnnouncement: String
    ) {
        self.init(
            key: key,
            style: .init { _ in style },
            content: content,
            accessibilityAnnouncement: accessibilityAnnouncement
        )
    }

    /// Fetch the toast presentation style for the given view environment.
    public func presentationStyle(for viewEnvironment: ViewEnvironment) -> ToastPresentationStyle {
        style.presentationStyle(for: viewEnvironment)
    }
}


extension Toast where Content: ToastPresentable {
    /// Convenience init for creating a toast with content that conforms to
    /// `ToastPresentable`. The style specified by the screen will be used for this modal.
    public init(
        key: some Hashable,
        content: Content
    ) {
        self.init(
            key: key,
            style: content.presentationStyle,
            content: content,
            accessibilityAnnouncement: content.accessibilityAnnouncement
        )
    }
}


extension Toast where Content: Screen {

    /// Erases to a `Toast<AnyScreen>` for display in a `AnyModalToastContainerViewController`.
    func asAnyScreenToast() -> Toast<AnyScreen> {
        Toast<AnyScreen>(
            key: key,
            style: style,
            content: content.asAnyScreen(),
            accessibilityAnnouncement: accessibilityAnnouncement
        )
    }

    func kind(in environment: ViewEnvironment) -> ViewControllerDescription.KindIdentifier {
        content.viewControllerDescription(environment: environment).kind
    }
}


extension Toast where Content == AnyScreen {
    /// Convenience init for creating a generic toast with content that conforms to `Screen`
    /// The provided screen will be wrapped in an `AnyScreen` instance.
    public init(
        key: some Hashable,
        style: ToastPresentationStyleProvider,
        screen: some Screen,
        accessibilityAnnouncement: String
    ) {
        self.init(
            key: key,
            style: style,
            content: AnyScreen(screen),
            accessibilityAnnouncement: accessibilityAnnouncement
        )
    }

    /// Convenience init for creating a toast with a static presentation style.
    /// The provided screen will be wrapped in an `AnyScreen` instance.
    public init(
        key: some Hashable,
        style: ToastPresentationStyle,
        screen: some Screen,
        accessibilityAnnouncement: String
    ) {
        self.init(
            key: key,
            style: .init { _ in style },
            content: AnyScreen(screen),
            accessibilityAnnouncement: accessibilityAnnouncement
        )
    }

    /// Convenience init for creating a toast with content that conforms to `ToastPresentable`. The style specified by
    /// the screen will be used for this toast.
    /// The provided screen will be wrapped in an `AnyScreen` instance.
    public init(
        key: some Hashable,
        screen: some Screen & ToastPresentable
    ) {
        self.init(
            key: key,
            style: screen.presentationStyle,
            content: AnyScreen(screen),
            accessibilityAnnouncement: screen.accessibilityAnnouncement
        )
    }
}

