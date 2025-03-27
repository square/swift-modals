import XCTest
@testable import Modals

final class VisibilityTests: XCTestCase {
    func test_transitions() {

        func assertTransition(
            from start: Visibility,
            to end: Visibility,
            expectedEvents: [LifecycleEvent],
            line: UInt = #line
        ) {
            let vc = LifecycleTestViewController()

            // UIKit will complain about unbalanced calls unless we get into the start state properly.
            switch start {
            case .disappeared:
                break
            case .appearing:
                vc.beginAppearanceTransition(true, animated: false)
            case .appeared:
                vc.beginAppearanceTransition(true, animated: false)
                vc.endAppearanceTransition()
            case .disappearing:
                vc.beginAppearanceTransition(true, animated: false)
                vc.beginAppearanceTransition(false, animated: false)
            }
            vc.events.removeAll()

            vc.callAppearanceTransitions(from: start, to: end, animated: false)

            XCTAssertEqual(vc.events, expectedEvents, line: line)
        }

        assertTransition(from: .disappeared, to: .disappeared, expectedEvents: [])
        assertTransition(from: .disappeared, to: .appearing, expectedEvents: [.willAppear])
        assertTransition(from: .disappeared, to: .appeared, expectedEvents: [.willAppear, .didAppear])
        assertTransition(from: .disappeared, to: .disappearing, expectedEvents: [.willAppear, .willDisappear])

        assertTransition(from: .appearing, to: .appearing, expectedEvents: [])
        assertTransition(from: .appearing, to: .appeared, expectedEvents: [.didAppear])
        assertTransition(from: .appearing, to: .disappearing, expectedEvents: [.willDisappear])
        assertTransition(from: .appearing, to: .disappeared, expectedEvents: [.willDisappear, .didDisappear])

        assertTransition(from: .appeared, to: .appeared, expectedEvents: [])
        assertTransition(from: .appeared, to: .disappearing, expectedEvents: [.willDisappear])
        assertTransition(from: .appeared, to: .disappeared, expectedEvents: [.willDisappear, .didDisappear])
        assertTransition(from: .appeared, to: .appearing, expectedEvents: [.willDisappear, .willAppear])

        assertTransition(from: .disappearing, to: .disappearing, expectedEvents: [])
        assertTransition(from: .disappearing, to: .disappeared, expectedEvents: [.didDisappear])
        assertTransition(from: .disappearing, to: .appearing, expectedEvents: [.willAppear])
        assertTransition(from: .disappearing, to: .appeared, expectedEvents: [.willAppear, .didAppear])
    }

    func test_nestedVisibility() {
        XCTAssertEqual(
            Visibility.disappeared.within(containerState: .disappeared),
            .disappeared
        )
        XCTAssertEqual(
            Visibility.disappeared.within(containerState: .appearing),
            .disappeared
        )
        XCTAssertEqual(
            Visibility.disappeared.within(containerState: .appeared),
            .disappeared
        )
        XCTAssertEqual(
            Visibility.disappeared.within(containerState: .disappearing),
            .disappeared
        )

        XCTAssertEqual(
            Visibility.appearing.within(containerState: .disappeared),
            .disappeared
        )
        XCTAssertEqual(
            Visibility.appearing.within(containerState: .appearing),
            .appearing
        )
        XCTAssertEqual(
            Visibility.appearing.within(containerState: .appeared),
            .appearing
        )
        XCTAssertEqual(
            Visibility.appearing.within(containerState: .disappearing),
            .disappearing
        )

        XCTAssertEqual(
            Visibility.appeared.within(containerState: .disappeared),
            .disappeared
        )
        XCTAssertEqual(
            Visibility.appeared.within(containerState: .appearing),
            .appearing
        )
        XCTAssertEqual(
            Visibility.appeared.within(containerState: .appeared),
            .appeared
        )
        XCTAssertEqual(
            Visibility.appeared.within(containerState: .disappearing),
            .disappearing
        )

        XCTAssertEqual(
            Visibility.disappearing.within(containerState: .disappeared),
            .disappeared
        )
        XCTAssertEqual(
            Visibility.disappearing.within(containerState: .appearing),
            .disappearing
        )
        XCTAssertEqual(
            Visibility.disappearing.within(containerState: .appeared),
            .disappearing
        )
        XCTAssertEqual(
            Visibility.disappearing.within(containerState: .disappearing),
            .disappearing
        )
    }
}

final class LifecycleTestViewController: UIViewController {
    var events: [LifecycleEvent] = []
    var visibility: Visibility = .disappeared

    func assertVisibility(
        in validVisibilities: [Visibility],
        event: LifecycleEvent,
        line: UInt = #line
    ) {
        XCTAssert(
            validVisibilities.contains(visibility),
            "Invalid transition \(event) from visibility: \(visibility)",
            line: line
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        events.append(.willAppear)
        assertVisibility(in: [.disappeared, .disappearing], event: .willAppear)
        visibility = .appearing
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        events.append(.didAppear)
        assertVisibility(in: [.appearing], event: .didAppear)
        visibility = .appeared
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        events.append(.willDisappear)
        assertVisibility(in: [.appearing, .appeared], event: .willDisappear)
        visibility = .disappearing
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        events.append(.didDisappear)
        assertVisibility(in: [.disappearing], event: .didDisappear)
        visibility = .disappeared
    }
}

enum LifecycleEvent {
    case willAppear
    case didAppear
    case willDisappear
    case didDisappear
}
