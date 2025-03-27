import UIKit

extension UIViewController {

    /// Returns a contained view controller if this is a container type. Should be overriden by container VCs.
    /// This pattern is used in register to traverse container view controllers
    @objc open var wrappedContentViewController: UIViewController? {
        nil
    }
}
