import Combine
import Modals
import TestingSupport
import ViewEnvironment
import Workflow
import WorkflowCombine
import WorkflowUI
import XCTest
@testable import WorkflowModals


class WorkflowModalListProviderTests: XCTestCase {

    func test_updates() throws {
        let rendering = CurrentValueSubject<TestWorkflow.Rendering, Never>(.init(modals: [], toasts: []))
        let output = PassthroughSubject<TestWorkflow.Output, Never>()

        var outputCount = 0

        rendering.value = .init(
            modals: [
                Modal(
                    key: "modal-1",
                    style: .init { env in
                        FullScreenModalStyle(
                            key: env.testString + "(1)",
                            environmentCustomization: { $0.testBool = true }
                        )
                    },
                    screen: EmptyScreen()
                ),
            ],
            toasts: [
                Toast(
                    key: "toast-1",
                    style: .init { ToastPresentationStyleFixture(key: $0.testString + "(1)") },
                    screen: EmptyScreen(),
                    accessibilityAnnouncement: "announcement"
                ),
            ]
        )

        let outputExpectation = XCTestExpectation(description: "Output should be sent")
        let provider = WorkflowModalListProvider(
            workflow: TestWorkflow(
                rendering: rendering,
                output: output
            ),
            onOutput: { _ in
                outputCount += 1
                outputExpectation.fulfill()
            }
        )

        var modalListDidChangeCount = 0

        let cancellable: AnyCancellable? = provider.modalListDidChange.sink { modalListDidChangeCount += 1 }

        XCTAssertEqual(outputCount, 0)

        var modalList = provider.aggregateModalList()

        // Aggregation should be empty until a valid environment is provided
        XCTAssertTrue(modalList.modals.isEmpty)
        XCTAssertTrue(modalList.toasts.isEmpty)
        XCTAssertEqual(modalListDidChangeCount, 0)

        var environment: ViewEnvironment = .empty
        environment.testString = "initial"
        provider.update(environment: environment)

        modalList = provider.aggregateModalList()

        func modalPresentationKeys(for modalList: ModalList) -> [String] {
            modalList.modals.map { ($0.presentationStyle as! FullScreenModalStyle).key }
        }

        func toastPresentationKeys(for modalList: ModalList) -> [String] {
            modalList.toasts.map { ($0.presentationStyle as! ToastPresentationStyleFixture).key }
        }

        XCTAssertEqual(modalList.modals.count, 1)
        XCTAssertEqual(modalList.toasts.count, 1)
        XCTAssertEqual(modalListDidChangeCount, 1)
        XCTAssertEqual(
            modalPresentationKeys(for: modalList),
            ["initial(1)"]
        )
        XCTAssertEqual(
            toastPresentationKeys(for: modalList),
            ["initial(1)"]
        )

        // Assert that environment customizations defined on the presentation style are respected
        let initialModal = try XCTUnwrap(modalList.modals.first)
        XCTAssertTrue(initialModal.viewController.environment.testBool)

        rendering.value = .init(
            modals: [
                Modal(
                    key: "modal-1",
                    style: .init { FullScreenModalStyle(key: $0.testString + "(1)") },
                    screen: EmptyScreen()
                ),
                Modal(
                    key: "modal-2",
                    style: .init { FullScreenModalStyle(key: $0.testString + "(2)") },
                    screen: EmptyScreen()
                ),
            ],
            toasts: [
                Toast(
                    key: "toast-1",
                    style: .init { ToastPresentationStyleFixture(key: $0.testString + "(1)") },
                    screen: EmptyScreen(),
                    accessibilityAnnouncement: "announcement"
                ),
                Toast(
                    key: "toast-2",
                    style: .init { ToastPresentationStyleFixture(key: $0.testString + "(2)") },
                    screen: EmptyScreen(),
                    accessibilityAnnouncement: "announcement"
                ),
            ]
        )

        do {
            let expectation = XCTestExpectation(description: "modalListDidChange should send an event on update.")
            let cancellable = provider.modalListDidChange.sink { expectation.fulfill() }
            wait(for: [expectation], timeout: 5)
            withExtendedLifetime(cancellable) {}
        }

        modalList = provider.aggregateModalList()

        XCTAssertEqual(modalList.modals.count, 2)
        XCTAssertEqual(modalList.toasts.count, 2)
        XCTAssertEqual(modalListDidChangeCount, 3)
        XCTAssertEqual(
            modalPresentationKeys(for: modalList),
            ["initial(1)", "initial(2)"]
        )
        XCTAssertEqual(
            toastPresentationKeys(for: modalList),
            ["initial(1)", "initial(2)"]
        )

        environment.testString = "updated"
        provider.update(environment: environment)

        modalList = provider.aggregateModalList()

        XCTAssertEqual(modalList.modals.count, 2)
        XCTAssertEqual(modalList.toasts.count, 2)
        XCTAssertEqual(modalListDidChangeCount, 4)
        XCTAssertEqual(
            modalPresentationKeys(for: modalList),
            ["updated(1)", "updated(2)"]
        )
        XCTAssertEqual(
            toastPresentationKeys(for: modalList),
            ["updated(1)", "updated(2)"]
        )

        XCTAssertEqual(outputCount, 0)
        output.send(())
        wait(for: [outputExpectation], timeout: 5)
        XCTAssertEqual(outputCount, 1)

        withExtendedLifetime(cancellable) { _ in }
    }
}


private struct TestWorkflow: Workflow {

    typealias Rendering = ModalsRendering<AnyScreen, AnyScreen>
    typealias State = Rendering
    typealias Output = Void

    let rendering: CurrentValueSubject<Rendering, Never>
    let output: PassthroughSubject<Output, Never>

    func makeInitialState() -> Rendering {
        rendering.value
    }

    func render(state: State, context: RenderContext<Self>) -> Rendering {
        rendering
            .mapOutput { rendering in
                AnyWorkflowAction {
                    $0 = rendering
                    return nil
                }
            }
            .running(in: context)

        output
            .mapOutput { output in
                AnyWorkflowAction { _ in
                    output
                }
            }
            .running(in: context)

        return state
    }
}


extension ViewEnvironment {
    fileprivate var testString: String {
        get { self[StringKey.self] }
        set { self[StringKey.self] = newValue }
    }

    private struct StringKey: ViewEnvironmentKey {
        static var defaultValue = ""
    }

    fileprivate var testBool: Bool {
        get { self[BoolKey.self] }
        set { self[BoolKey.self] = newValue }
    }

    private struct BoolKey: ViewEnvironmentKey {
        static var defaultValue = false
    }
}
