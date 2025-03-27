import Modals
import Workflow
import WorkflowUI


extension ModalListObserver {

    /// Observes a ``Workflow`` that renders a list of modals and toasts, and presents for the duration of the returned
    /// lifetime token.
    ///
    /// This method internally creates a `WorkflowHost` to render the workflow, and then uses the same mechanisms as a
    /// `ModalContainer` to realize each modal screen's view controllers, and to bridge the owning view controller's
    /// `ViewEnvironment` to the Workflow's`ViewEnvironment`.
    ///
    /// The rendered modals will be added to the list of modals on the view controller that owns this observer.
    ///
    /// - Note: When possible, refactoring your view controller into a workflow and rendering your modals with a
    ///   `ModalContainer` directly is a preferable approach to the bridging provided here.
    ///
    /// - Parameters:
    ///   - workflow: The `Workflow` to observe.
    ///   - onOutput: The action to perform when output is sent by the `workflow`.
    ///
    /// - Returns: A token that must be kept to continue observing and presenting modals.
    ///
    public func observe<WorkflowType, ModalContent, ToastContent>(
        _ workflow: WorkflowType,
        onOutput: @escaping (WorkflowType.Output) -> Void
    ) -> ModalListObservationLifetime where
        WorkflowType: AnyWorkflowConvertible,
        ModalContent: Screen,
        ToastContent: Screen,
        WorkflowType.Rendering == ModalsRendering<ModalContent, ToastContent>
    {
        observe(WorkflowModalListProvider(
            workflow: workflow,
            onOutput: onOutput
        ))
    }
}
