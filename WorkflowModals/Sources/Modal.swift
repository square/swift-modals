import Modals
import WorkflowUI

public typealias AnyModal = Modal<AnyScreen>


/// Use this type to provide a key and modal presentation style for content presented in a
/// [ModalContainer](x-source-tag://ModalContainer).
///
public struct Modal<Content> {
    /// The key is used to determine which modals are presented and dismissed when the modal
    /// container updates its screen. While they don't need to be unique, they must be consistent
    /// or your modal will animate in and out when the screen updates.
    public var key: AnyHashable

    /// Provides a style for the modal based on the `ViewEnvironment` the screen is rendered in.
    public var style: ModalPresentationStyleProvider

    /// Additional Information associated with the modal presentation.
    public var info: ModalInfo

    /// The content of the modal.
    public var content: Content

    /// Called after the modal is physically removed from an individual presenter, independent of
    /// appearance state. This does not mean the workflow that rendered it has finished, and forwarding
    /// may leave the content presented by another host. See `PresentableModal.onDidRemove`.
    public var onDidRemove: (() -> Void)?

    /// Create a new modal.
    public init(
        key: some Hashable,
        style: ModalPresentationStyleProvider,
        info: ModalInfo = .empty(),
        onDidRemove: (() -> Void)? = nil,
        content: Content
    ) {
        self.key = AnyHashable(key)
        self.style = style
        self.info = info
        self.content = content
        self.onDidRemove = onDidRemove
    }

    /// Convenience init for creating a modal with a static presentation style.
    public init(
        key: some Hashable,
        style: ModalPresentationStyle,
        info: ModalInfo = .empty(),
        onDidRemove: (() -> Void)? = nil,
        content: Content
    ) {
        self.init(
            key: key,
            style: .init(style),
            info: info,
            onDidRemove: onDidRemove,
            content: content
        )
    }

    /// Fetch the modal presentation style for the given view environment.
    public func presentationStyle(for viewEnvironment: ViewEnvironment) -> ModalPresentationStyle {
        style.presentationStyle(for: viewEnvironment)
    }

    /// Map the content of the modal to a new modal with the same key and presentation style.
    /// - Parameter transform: Closure to transform the content of the modal.
    /// - Returns: The transformed modal.
    public func map<NewContent>(_ transform: (Content) -> NewContent) -> Modal<NewContent> {
        Modal<NewContent>(
            key: key,
            style: style,
            onDidRemove: onDidRemove,
            content: transform(content)
        )
    }
}

extension Modal where Content: ModalPresentable {
    /// Convenience init for creating a modal with content that conforms to
    /// `ModalPresentable`. The style specified by the screen will be used for this modal.
    public init(
        key: some Hashable,
        onDidRemove: (() -> Void)? = nil,
        content: Content
    ) {
        self.init(
            key: key,
            style: content.presentationStyle,
            info: content.info,
            onDidRemove: onDidRemove,
            content: content
        )
    }
}

extension Modal where Content: Screen {

    /// Erases to a `Modal<AnyScreen>` for display in a `AnyModalToastContainerViewController`.
    func asAnyScreenModal() -> Modal<AnyScreen> {
        Modal<AnyScreen>(
            key: key,
            style: style,
            info: info,
            onDidRemove: onDidRemove,
            content: content.asAnyScreen()
        )
    }

    func kind(in environment: ViewEnvironment) -> ViewControllerDescription.KindIdentifier {
        content.viewControllerDescription(environment: environment).kind
    }
}

extension Modal where Content == AnyScreen {
    /// Convenience init for creating a generic modal with content that conforms to `Screen`
    /// The provided screen will be wrapped in an `AnyScreen` instance.
    public init(
        key: some Hashable,
        style: ModalPresentationStyleProvider,
        info: ModalInfo = .empty(),
        onDidRemove: (() -> Void)? = nil,
        screen: some Screen
    ) {
        self.init(
            key: key,
            style: style,
            info: info,
            onDidRemove: onDidRemove,
            content: AnyScreen(screen)
        )
    }

    /// Convenience init for creating a modal with a static presentation style.
    /// The provided screen will be wrapped in an `AnyScreen` instance.
    public init(
        key: some Hashable,
        style: ModalPresentationStyle,
        info: ModalInfo = .empty(),
        onDidRemove: (() -> Void)? = nil,
        screen: some Screen
    ) {
        self.init(
            key: key,
            style: .init(style),
            info: info,
            onDidRemove: onDidRemove,
            content: AnyScreen(screen)
        )
    }

    /// Convenience init for creating a modal with content that conforms to
    /// `ModalPresentable`. The style specified by the screen will be used for this modal.
    /// The provided screen will be wrapped in an `AnyScreen` instance.
    public init(
        key: some Hashable,
        onDidRemove: (() -> Void)? = nil,
        screen: some Screen & ModalPresentable
    ) {
        self.init(
            key: key,
            style: screen.presentationStyle,
            info: screen.info,
            onDidRemove: onDidRemove,
            content: AnyScreen(screen)
        )
    }
}


extension Screen {

    /// Wraps the screen in the provided modal style, with the given key.
    public func modal(
        key: AnyHashable,
        style: ModalPresentationStyleProvider,
        info: ModalInfo = .empty(),
        onDidRemove: (() -> Void)? = nil
    ) -> Modal<Self> {
        Modal(
            key: key,
            style: style,
            info: info,
            onDidRemove: onDidRemove,
            content: self
        )
    }

}


extension Screen where Self: ModalPresentable {

    /// Wraps the modal presentable screen with the given key.
    public func modal(
        key: AnyHashable,
        onDidRemove: (() -> Void)? = nil
    ) -> Modal<Self> {
        Modal(key: key, onDidRemove: onDidRemove, content: self)
    }
}
