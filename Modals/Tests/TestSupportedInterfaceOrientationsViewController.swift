import UIKit


final class TestSupportedInterfaceOrientationsViewController: UIViewController {

    private let supportedOrientations: UIInterfaceOrientationMask

    init(supportedOrientations: UIInterfaceOrientationMask) {
        self.supportedOrientations = supportedOrientations

        super.init(nibName: nil, bundle: nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { supportedOrientations }

    required init?(coder: NSCoder) { fatalError() }
}
