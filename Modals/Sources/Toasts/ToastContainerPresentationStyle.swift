import UIKit


/// The toast presentation system uses a toast presentation style to determine the appearance and behavior of the toast
/// container. This includes:
/// - the size and position of presented toasts
/// - transitions
/// - chrome UI, such as shadows
///
/// This the is the main customization point for changing the way toasts appear on screen.
///
/// - Note: Adding conformance to `Equatable` will allow for the default implementation of `isEqual(to:)` to be used.
///
public protocol ToastContainerPresentationStyle {

    /// Calculates the view state of all toasts as if they are in the "presented" state.
    ///
    /// The context provided to this function includes the sizes of each toast "preheated".
    func displayValues(for context: ToastDisplayContext) -> ToastDisplayValues

    /// Calculates the view state of a specific toast for the enter transition.
    ///
    /// All values returned should describe the view state of the toast at the start of the transition.
    ///
    /// The provided context includes the frame of the toast in the "presented" state.
    func enterTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues

    /// Calculates the view state of a specific toast for the exit transition.
    ///
    /// All values returned should describe the view state of the toast at the end of the transition.
    ///
    /// The provided context includes the frame of the toast in the "presented" state.
    func exitTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues

    /// Calculates the view state of a specific toast during an interactive exit transition.
    ///
    /// All values returned should describe the view state of the toast at the end of the transition.
    ///
    /// The provided context includes the frame of the toast in the "presented" state.
    func interactiveExitTransitionValues(for context: ToastInteractiveExitContext) -> ToastTransitionValues

    /// Calculates the view state of a specific toast during a reverse interactive exit transition.
    ///
    /// All values returned should describe the view state of the toast at the end of the transition.
    ///
    /// The provided context includes the frame of the toast in the "presented" state.
    func reverseTransitionValues(for context: ToastTransitionContext) -> ToastTransitionValues

    /// Returns the available size for each toast to layout in during the "preheat" pass
    ///
    /// The Toast's view controller contents are laid out in sizes returned from this function before the
    /// `preferredContentSize` is queried.
    func preheatValues(for context: ToastPreheatContext) -> ToastPreheatValues

    /// Determines if two instances of a presentation style are equal.
    ///
    /// This is used to skip layouts when the environment updates, yet no changes to the style have been made between
    /// those updates.
    ///
    /// Conforming types can conform to `Equatable` to get an implementation of this function "for free".
    func isEqual(to other: ToastContainerPresentationStyle) -> Bool
}

extension ToastContainerPresentationStyle where Self: Equatable {

    public func isEqual(to other: ToastContainerPresentationStyle) -> Bool {
        guard let other = other as? Self else {
            return false
        }

        return self == other
    }
}
