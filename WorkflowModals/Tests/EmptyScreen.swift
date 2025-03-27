import WorkflowUI

struct EmptyScreen: Screen {
    func viewControllerDescription(environment: ViewEnvironment) -> ViewControllerDescription {
        EmptyViewController.description(for: self, environment: environment)
    }
}

final class EmptyViewController: ScreenViewController<EmptyScreen> {}
