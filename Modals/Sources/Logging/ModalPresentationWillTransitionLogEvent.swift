import Logging
import UIKit

#if !os(watchOS)
/// Strutured log event metadata that represents a modal presentation transition is about to happen.
///
/// Log consumers can identify this event from the ``ModalsLogging/defaultLoggerLabel`` logger and
/// unmarshal it using the ``init(metadata:)`` initializer.
public struct ModalPresentationWillTransitionLogEvent: CustomStringConvertible {

    public static let eventType = "\(ModalsLogging.defaultLoggerLabel).willtransition"

    /// The view controller running the transition operation
    public let presenterViewController: UIViewController

    /// The current view controller we are transitioning from
    public let fromViewController: UIViewController

    /// The view controller we will be transitioning to
    public let toViewController: UIViewController

    /// The type of transition
    public let transitionState: TransitionState

    /// Whether the transition operation is animated
    public let animated: Bool

    public var metadata: Logging.Logger.Metadata {
        [
            "eventType": .stringConvertible(Self.eventType),
            "presenterViewController": .stringConvertible(presenterViewController),
            "fromViewController": .stringConvertible(fromViewController),
            "toViewController": .stringConvertible(toViewController),
            "transitionState": .stringConvertible(transitionState),
            "animated": .stringConvertible(animated),
        ]
    }

    public init(
        presenterViewController: UIViewController,
        fromViewController: UIViewController,
        toViewController: UIViewController,
        transitionState: TransitionState,
        animated: Bool
    ) {
        self.presenterViewController = presenterViewController
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        self.transitionState = transitionState
        self.animated = animated
    }

    public init?(metadata: Logging.Logger.Metadata) {
        guard
            case .stringConvertible(let eventType as String) = metadata["eventType"],
            eventType == Self.eventType
        else {
            return nil
        }

        guard case .stringConvertible(let presenterViewController as UIViewController) = metadata["presenterViewController"] else { return nil }
        self.presenterViewController = presenterViewController

        guard case .stringConvertible(let fromViewController as UIViewController) = metadata["fromViewController"] else { return nil }
        self.fromViewController = fromViewController

        guard case .stringConvertible(let toViewController as UIViewController) = metadata["toViewController"] else { return nil }
        self.toViewController = toViewController

        guard case .stringConvertible(let animated as Bool) = metadata["animated"] else { return nil }
        self.animated = animated

        guard case .stringConvertible(let transitionState as TransitionState) = metadata["transitionState"] else { return nil }
        self.transitionState = transitionState
    }

    public var description: String {
        "\(Self.self) from \(fromViewController) to \(toViewController) presented by \(presenterViewController) animated: \(animated)"
    }

    public enum TransitionState: String, CustomStringConvertible {
        case entering, exiting

        public var description: String { rawValue }
    }
}
#endif
