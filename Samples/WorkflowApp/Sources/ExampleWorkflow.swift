import UIKit
import Workflow
import WorkflowModals
import WorkflowUI

struct ExampleWorkflow: Workflow {
    typealias Rendering = ModalContainer<ExampleScreen, AnyScreen>

    enum Action: WorkflowAction {
        typealias WorkflowType = ExampleWorkflow

        case present(ExamplePresentation)
        case dismiss

        func apply(toState state: inout ExampleWorkflow.State) -> ExampleWorkflow.Output? {
            switch self {
            case .present(let presentation):
                state.presentation = presentation
            case .dismiss:
                state.presentation = nil
            }
            return nil
        }
    }

    enum Output {
        case dismissed
    }

    struct State {
        var presentation: ExamplePresentation?
    }

    // If true, don't show the dismiss button
    var isRootWorkflow = false

    func makeInitialState() -> State {
        State()
    }

    func render(state: State, context: RenderContext<ExampleWorkflow>) -> Rendering {
        let sink = context.makeSink(of: Action.self)
        let outputSink = context.makeOutputSink()

        // If we are in a presenting state, render a child workflow and wrap it in a modal.
        // We must erase to AnyScreen because we're recursively rendering the same workflow.
        var childScreen: AnyScreen {
            ExampleWorkflow().rendered(
                in: context,
                outputMap: { output in
                    switch output {
                    case .dismissed:
                        Action.dismiss
                    }
                }
            )
            .asAnyScreen()
        }

        return ModalContainer {
            ExampleScreen(
                onPresent: { exampleStyle, coordinateSpace in
                    switch exampleStyle {
                    case .full:
                        sink.send(.present(.full))
                    case .card:
                        sink.send(.present(.card))
                    case .popover:
                        sink.send(.present(.popover(anchor: coordinateSpace)))
                    case .sheet:
                        sink.send(.present(.sheet))
                    }
                },
                onDismiss: isRootWorkflow
                    ? nil
                    : { outputSink.send(.dismissed) }
            )
        } modals: {
            switch state.presentation {
            case .full:
                Modal(
                    key: "full-modal",
                    style: .full,
                    screen: childScreen
                )

            case .card:
                Modal(
                    key: "card-modal",
                    style: .card,
                    screen: childScreen
                )

            case .popover(let anchor):
                Modal(
                    key: "popover",
                    style: .popover(anchor: anchor, onDismiss: { sink.send(.dismiss) }),
                    content: childScreen
                )

            case .sheet:
                Modal(
                    key: "sheet",
                    style: .sheet(onDismiss: { sink.send(.dismiss) }),
                    content: childScreen
                )

            case .none:
                []
            }
        }
    }
}

enum ExamplePresentation {
    case full
    case card
    case popover(anchor: UICoordinateSpace)
    case sheet
}
