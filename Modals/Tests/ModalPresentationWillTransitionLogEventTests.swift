import Logging
import Modals
import XCTest

final class ModalPresentationWillTransitionLogEventTests: XCTestCase {

    private let presenterViewController = SampleViewController<Int>()
    private let fromViewController = SampleViewController<Int>()
    private let toViewController = SampleViewController<Int>()

    func test_convertibility() {
        let animated = true
        let state = ModalPresentationWillTransitionLogEvent.TransitionState.entering
        let event = ModalPresentationWillTransitionLogEvent(
            presenterViewController: presenterViewController,
            fromViewController: fromViewController,
            toViewController: toViewController,
            transitionState: state,
            animated: animated
        )

        let metadata = event.metadata

        XCTAssertEqual(metadata, [
            "eventType": .stringConvertible(ModalPresentationWillTransitionLogEvent.eventType),
            "presenterViewController": .stringConvertible(presenterViewController),
            "fromViewController": .stringConvertible(fromViewController),
            "toViewController": .stringConvertible(toViewController),
            "transitionState": .stringConvertible(state),
            "animated": .stringConvertible(animated),
        ])

        guard let restored = ModalPresentationWillTransitionLogEvent(metadata: metadata) else {
            XCTFail("Failed restoring event")
            return
        }

        XCTAssertEqual(restored.presenterViewController, presenterViewController)
        XCTAssertEqual(restored.fromViewController, fromViewController)
        XCTAssertEqual(restored.toViewController, toViewController)
        XCTAssertEqual(restored.transitionState, state)
        XCTAssertEqual(restored.animated, animated)
    }

    func test_failing_conversion() {
        let metadata: Logger.Metadata = [
            "presenterViewController": .stringConvertible(presenterViewController),
            "fromViewController": .stringConvertible(fromViewController),
            "toViewController": .stringConvertible(toViewController),
            "wrongKey": .stringConvertible(false),
        ]

        let converted = ModalPresentationWillTransitionLogEvent(metadata: metadata)
        XCTAssertNil(converted)
    }
}

class SampleViewController<T>: UIViewController {}
