import ExampleStyles
import Modals
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let root = ModalHostContainerViewController(
            content: ExampleViewController(),
            toastContainerStyle: .example
        )
        root.view.backgroundColor = .systemBackground

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = root
        window?.makeKeyAndVisible()

        return true
    }
}
