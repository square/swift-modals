import UIKit
import ViewEnvironment


/// This type provides a `ToastPresentationStyle` based on the `ViewEnvironment`.
///
/// Toasts sometimes need dynamic styles that can be updated when the "environment" changes (e.g., the theme or some
/// traits about the context the toast is rendered in have changed). This type allows us to symbolically represent
/// styles, by deferring resolving the actual `ToastPresentationStyle` until the environment is available, and allows us
/// to get an updated style when the environment changes.
///
public struct ToastPresentationStyleProvider {

    /// Closure alias that takes in an `Environment` and returns a `ToastPresentationStyle`.
    ///
    public typealias ProvideStyle = (ViewEnvironment) -> ToastPresentationStyle

    /// The provider closure.
    ///
    public var provider: ProvideStyle

    /// Create a new `ToastPresentationStyleProvider` that builds a style with a provider.
    ///
    public init(_ provideStyle: @escaping ProvideStyle) {
        provider = provideStyle
    }

    /// Create a new `ToastContainerPresentationStyleProvider` with a concrete style.
    ///
    public init(_ style: ToastPresentationStyle) {
        provider = { _ in style }
    }

    /// Convenience method for fetching the presentation style for a given environment.
    ///
    public func presentationStyle(for environment: ViewEnvironment) -> ToastPresentationStyle {
        provider(environment)
    }
}
