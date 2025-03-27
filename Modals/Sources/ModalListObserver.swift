import Combine
import ViewEnvironment


/// Observes a list of modals and/or toasts, presenting and dismissing them as the list dynamically changes over time.
///
/// This interface provides a reactive alternative to the imperative presentation methods on `ModalPresenter`.
///
/// A concrete implementation of this type can be access on `UIViewController`:
/// [`modalListObserver`](x-source-tag://UIViewController.modalListObserver).
///
public protocol ModalListObserver {

    /// Begins the observation of a ``ModalListProvider``. The modals from the observed object will be added to the
    /// list of modals on the view controller that owns this observer.
    ///
    /// This function returns a token that must be retained. To stop observing a list and dismiss related modals, call
    /// the `stopObserving` method on the token. If the token is deallocated, `stopObserving` will be called
    /// automatically.
    ///
    /// - Parameter provider: A provider to begin observing. Modals from the list will be presented and dismissed
    ///   dynamically as the list changes over time.
    ///
    /// - Returns: A token that must be kept to continue observing and presenting modals.
    ///
    func observe(_ provider: ModalListProvider) -> ModalListObservationLifetime
}


/// A type that provides a list of modals and/or toasts that can change over time.
///
public protocol ModalListProvider: AnyObject {

    /// Updates the `ViewEnvironment` used for modal presentation styles and the content of the modals.
    ///
    /// Called by the observer when observation begins, and whenever the `ViewEnvironment` needs to be re-applied.
    ///
    func update(environment: ViewEnvironment)

    /// Returns the presented modals associated with this observer, and any descendants of those modals.
    ///
    /// The observer will call this when its owning view controller is aggregating modals.
    ///
    /// ## See Also:
    /// - [UIViewController.aggregateModals()](x-source-tag://UIViewController.aggregateModals)
    ///
    func aggregateModalList() -> ModalList

    /// Sends `Void` whenever the `ModalList` content should be re-requested (e.g. the list of modals changes).
    ///
    var modalListDidChange: AnyPublisher<Void, Never> { get }
}


/// An opaque token used to end a `ModalListObserver` observation.
///
/// If this token is deallocated, the observation will end automatically and all modals currently observed will be
/// dismissed.
///
/// - SeeAlso: ``ModalListObserver``
///
public protocol ModalListObservationLifetime: AnyObject {

    /// Ends the modal list observation lifetime associated with this token.
    ///
    func stopObserving()
}
