import Logging
import Modals
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        LoggingSystem.bootstrap { _ in
            SwiftLogNoOpLogHandler()
        }

        ToastPresentationViewController.configure(with: application)

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()

        window?.makeKeyAndVisible()

        return true
    }
}
