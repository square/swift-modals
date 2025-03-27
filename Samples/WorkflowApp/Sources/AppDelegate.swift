import UIKit
import Workflow
import WorkflowModals
import WorkflowUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let root = WorkflowHostingController(
            workflow: ExampleWorkflow(isRootWorkflow: true).mapRendering { content in
                ModalHostContainer(content: content, toastContainerStyle: .example)
            }
        )
        root.view.backgroundColor = .systemBackground

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = root
        window?.makeKeyAndVisible()

        return true
    }
}
