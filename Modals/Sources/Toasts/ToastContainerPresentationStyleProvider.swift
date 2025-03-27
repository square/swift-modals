import ViewEnvironment


/// This type provides a `ToastContainerPresentationStyle` based on the generic `Environment` type.
///
/// Toasts sometimes need dynamic styles that can be updated when the "environment" changes (e.g., the theme or some
/// traits about the context the toast is rendered in have changed). This type allows us to symbolically represent
/// styles, by deferring resolving the actual `ToastContainerPresentationStyle` until the environment is available, and
/// allows us to get an updated style when the environment changes.
///
/// The toast presentation infrastructure uses the concrete `ToastContainerPresentationStyleProvider`
/// typealias for toast presentation, but this type is generic so it can be used with other environment types.
///
public struct ToastContainerPresentationStyleProvider {

    /// Closure alias that takes in an `Environment` and returns a `ToastContainerPresentationStyle`.
    ///
    public typealias ProvideStyle = (ViewEnvironment) -> ToastContainerPresentationStyle

    /// The provider closure.
    ///
    public var provider: ProvideStyle

    /// Create a new `ToastContainerPresentationStyleProvider` that builds a style with a provider.
    ///
    public init(_ provideStyle: @escaping ProvideStyle) {
        provider = provideStyle
    }

    /// Create a new `ToastContainerPresentationStyleProvider` with a concrete style.
    ///
    public init(_ style: ToastContainerPresentationStyle) {
        provider = { _ in style }
    }

    /// Convenience method for fetching the presentation style for a given environment.
    ///
    public func style(for environment: ViewEnvironment) -> ToastContainerPresentationStyle {
        provider(environment)
    }
}
