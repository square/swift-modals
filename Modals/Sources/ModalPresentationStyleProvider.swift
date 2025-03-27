import ViewEnvironment


/// This type provides a `ModalPresentationStyle` based on the `ViewEnvironment`.
///
/// Modals sometimes need dynamic styles that can be updated when the "environment" changes (e.g.,
/// the theme or some traits about the context the modal is rendered in have changed). This type
/// allows us to symbolically represent styles, by deferring resolving the actual
/// `ModalPresentationStyle` until the environment is available, and allows us to get an updated
/// style when the environment changes.
///
public struct ModalPresentationStyleProvider {

    /// Closure alias that takes in a `ViewEnvironment` and returns a `ModalPresentationStyle`.
    public typealias ProvideStyle = (ViewEnvironment) -> ModalPresentationStyle

    /// The provider closure.
    public var provider: ProvideStyle

    /// Create a new provider.
    /// - Parameters:
    ///   - provideStyle: A closure to resolve a modal style from the environment.
    public init(_ provideStyle: @escaping ProvideStyle) {
        provider = provideStyle
    }

    /// Create a new provider with a concrete style.
    /// - Parameters:
    ///   - style: A modal style.
    public init(_ style: ModalPresentationStyle) {
        self.init { _ in style }
    }

    /// Convenience method for fetching the presentation style for a given environment.
    public func presentationStyle(for environment: ViewEnvironment) -> ModalPresentationStyle {
        provider(environment)
    }
}
