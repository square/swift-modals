import UIKit
import ViewEnvironment

/// The modal presentation system uses a modal presentation style to determine the appearance and
/// behavior of a modal. This includes:
/// - the container size and position
/// - transitions
/// - chrome UI, such as shadows and the overlay view
///
/// This the is the main customization point for changing the way a modal behaves.
///
public protocol ModalPresentationStyle {

    /// Get the modal's behavior preferences, with the context where it is presented.
    ///
    /// This will be called to determine how certain behaviors are configured in the modal.
    func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences

    /// Get the modal's current display values, with the context where it is presented.
    ///
    /// The modal presentation system may call this repeatedly to update the modal in response to
    /// context changes.
    func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues

    /// Gets the initial values to use during the transition when this modal is appearing. The
    /// presentation system will animate the modal from these values into the values returned by
    /// `displayValues(for:)`.
    ///
    /// You should add support for `UIAccessibility.prefersCrossFadeTransitions` in your implementation for this
    /// function. E.g.:
    /// ````
    /// public func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
    ///     if !context.isInteractive, style.prefersCrossFadeTransitions {
    ///         return .crossFadeValues(from: displayValues(for: context))
    ///     }
    ///
    ///     ... // Return the standard transition values here.
    /// }
    /// ````
    func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues

    /// Gets the final values to use during the transition when this modal is disappearing. The
    /// presentation system will animate the modal from the values returned by `displayValues(for:)`
    /// to these values before removing it.
    ///
    /// You should add support for `UIAccessibility.prefersCrossFadeTransitions` in your implementation for this
    /// function. E.g.:
    /// ````
    /// public func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
    ///     if !context.isInteractive, style.prefersCrossFadeTransitions {
    ///         return .crossFadeValues(from: displayValues(for: context))
    ///     }
    ///
    ///     ... // Return the standard transition values here.
    /// }
    /// ````
    func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues

    /// Get the values to pan to when an interactive gesture is panned in the opposite direction of
    /// the outgoing direction. If no values are returned, then the interaction will have a
    /// hard-stop when panning in that direction, rather than rubber-banding.
    func reverseTransitionValues(for context: ModalPresentationContext) -> ModalReverseTransitionValues?

    /// Customizes the environment that is propagated to this modal's content.
    ///
    /// Modals inherit the environment from the view controller that presents them. You can use this
    /// customization point to apply any changes, and they will propagate to the modal as well as
    /// any content it subsequently presents.
    ///
    /// This is the recommended a way to communicate to the content about what type of modal style
    /// it is presented in.
    func customize(environment: inout ViewEnvironment)
}

extension ModalPresentationStyle {

    public func reverseTransitionValues(for context: ModalPresentationContext) -> ModalReverseTransitionValues? {
        nil
    }

    public func customize(environment: inout ViewEnvironment) {}
}

