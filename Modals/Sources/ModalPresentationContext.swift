import UIKit

/// Contextual information provided to a `ModalPresentationStyle` when getting display values.
public struct ModalPresentationContext {
    /// The coordinate space of the container presenting the modal.
    public var containerCoordinateSpace: UICoordinateSpace
    /// The safe area insets of the container presenting the modal.
    public var containerSafeAreaInsets: UIEdgeInsets
    /// The keyboard frame in the container's coordinate space.
    public var containerKeyboardFrame: CGRect?
    /// The preferred content size of the modal's view controller.
    ///
    /// This will be `unknown` if the modal's view controller has not yet laid out and provided a
    /// preferred content size (or if the view controller never provides a preferred content size).
    /// In that case, you should choose a modal frame based on the container size, or some other
    /// appropriate default.
    ///
    /// To ensure your view controller's preferredContentSize is used in the presentation context,
    /// make sure you set it sometime before the presentation occurs (viewDidLoad is early enough).
    public var preferredContentSize: PreferredContentSize
    /// The natural scale factor associated with the screen the modal is presented in.
    public var scale: CGFloat
    /// The current frame of the modal.
    ///
    /// This will be `undefined` if the modal is transitioning or has not been presented.
    public var currentFrame: CurrentFrame
    /// Indicates whether the presentation is requesting values for a state involving an interactive transition.
    ///
    /// You can use this value to determine whether it's appropriate to switch from a transition with movement to a
    /// cross-fade transition when the value of `UIAccessibility.prefersCrossFadeTransitions` is `true`. For example:
    /// ````
    /// public func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
    ///     if !context.isInteractive, style.prefersCrossFadeTransitions {
    ///         return .crossFadeValues(from: displayValues(for: context))
    ///     }
    ///
    ///     ... // Return the standard transition values here.
    /// }
    /// ````
    public var isInteractive: Bool

    /// Create a presentation context.
    public init(
        containerCoordinateSpace: UICoordinateSpace,
        containerSafeAreaInsets: UIEdgeInsets,
        containerKeyboardFrame: CGRect?,
        preferredContentSize: PreferredContentSize,
        currentFrame: CurrentFrame,
        scale: CGFloat,
        isInteractive: Bool
    ) {
        self.containerCoordinateSpace = containerCoordinateSpace
        self.containerSafeAreaInsets = containerSafeAreaInsets
        self.containerKeyboardFrame = containerKeyboardFrame
        self.preferredContentSize = preferredContentSize
        self.currentFrame = currentFrame
        self.scale = scale
        self.isInteractive = isInteractive
    }

    /// The viewport size.
    public var containerSize: CGSize {
        containerCoordinateSpace.bounds.size
    }
}

extension ModalPresentationContext {
    /// Represents the preferred content size provided by the modal's view controller, or the
    /// absence of a preferred content size.
    public enum PreferredContentSize: Equatable {
        /// The preferred content size as provided by the modal's view controller.
        case known(CGSize)
        /// Indicates that the modal's view controller has not provided a preferred content size.
        case unknown

        init(_ size: CGSize) {
            if size == .zero {
                self = .unknown
            } else {
                self = .known(size)
            }
        }

        /// The preferred content size, or `nil` if it is unknown.
        public var value: CGSize? {
            switch self {
            case .known(let size):
                size
            case .unknown:
                nil
            }
        }
    }

    /// Represents the current position of the modal in the containers coordinate space.
    public enum CurrentFrame: Equatable {
        /// The current position is known because the modal is presented.
        case known(CGRect)
        /// The position is unknown, because the modal is transitioning or has not been presented.
        case undefined

        /// The current frame of the modal, or `nil` if it is undefined.
        public var value: CGRect? {
            switch self {
            case .known(let frame):
                frame
            case .undefined:
                nil
            }
        }
    }
}
