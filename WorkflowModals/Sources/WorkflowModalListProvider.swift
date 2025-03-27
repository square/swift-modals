import Combine
import Modals
import ReactiveSwift
import ViewEnvironment
import Workflow
import WorkflowUI


/// A `ModalListProvider` that observes a `Workflow` which renders ``Modal``s and/or ``Toast`` without a base screen,
/// and converts them to a `ModalList` for aggregation in vanilla UIKit contexts.
///
final class WorkflowModalListProvider<WorkflowType, ModalContent, ToastContent>: ModalListProvider where
    WorkflowType: AnyWorkflowConvertible,
    ModalContent: Screen,
    ToastContent: Screen,
    WorkflowType.Rendering == ModalsRendering<ModalContent, ToastContent>
{

    private typealias Manager = PresentedModalsManager<ModalContent, ToastContent>

    private let workflowHost: WorkflowHost<RootWorkflow<WorkflowType.Rendering, WorkflowType.Output>>

    private let (lifetime, token) = Lifetime.make()

    private let manager = Manager()

    private let _modalListDidChange = PassthroughSubject<Void, Never>()

    private var contents: Manager.Contents {
        didSet { update() }
    }

    private var environment: ViewEnvironment? {
        didSet { update() }
    }

    init(
        workflow: WorkflowType,
        onOutput: @escaping (WorkflowType.Output) -> Void
    ) {
        workflowHost = .init(workflow: RootWorkflow(workflow))

        workflowHost.output
            .signal
            .take(during: lifetime)
            .observeValues(onOutput)

        contents = .init(
            modals: workflowHost.rendering.value.modals,
            toasts: workflowHost.rendering.value.toasts
        )
        workflowHost
            .rendering
            .signal
            .take(during: lifetime)
            .observeValues { [weak self] value in
                guard let self else { return }

                contents = .init(
                    modals: value.modals,
                    toasts: value.toasts
                )
            }
    }

    func update(environment: ViewEnvironment) {
        self.environment = environment
    }

    func aggregateModalList() -> ModalList {
        let presentedModalsAndAggregates = manager.presentedModals.map { modal in
            (modal.modal, modal.viewController.aggregateModals())
        }

        return ModalList(
            modals: presentedModalsAndAggregates.flatMap { [$0] + $1.modals },
            toasts: manager.presentedToasts.map { $0.toast }
                + presentedModalsAndAggregates.flatMap { $1.toasts }
        )
    }

    var modalListDidChange: AnyPublisher<Void, Never> {
        AnyPublisher(_modalListDidChange)
    }

    private func update() {
        guard let environment else { return }

        manager.update(
            contents: .init(
                modals: contents.modals,
                toasts: contents.toasts
            ),
            environment: environment
        )

        _modalListDidChange.send(())
    }
}


extension WorkflowModalListProvider {

    /// Wrapper around an AnyWorkflow that allows us to have a concrete `WorkflowHost` (which is generic over a
    /// `Workflow`) while still supporting `AnyWorkflow`/`AnyWorkflowConvertible` (which does not conform to
    /// `Workflow`).
    fileprivate struct RootWorkflow<Rendering, Output>: Workflow {
        typealias State = Void
        typealias Output = Output
        typealias Rendering = Rendering

        var wrapped: AnyWorkflow<Rendering, Output>

        init<W: AnyWorkflowConvertible>(_ wrapped: W) where W.Rendering == Rendering, W.Output == Output {
            self.wrapped = wrapped.asAnyWorkflow()
        }

        func render(state: State, context: RenderContext<RootWorkflow>) -> Rendering {
            wrapped
                .mapOutput { AnyWorkflowAction(sendingOutput: $0) }
                .rendered(in: context)
        }
    }
}
