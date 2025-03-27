import TestingSupport
import XCTest
@testable import Logging
@testable import Modals

final class ModalHostContainerViewControllerTests: XCTestCase {

    func test_preferredContentSize() {
        class SquareViewController: UIViewController {
            override func viewDidLayoutSubviews() {
                super.viewDidLayoutSubviews()

                let preferredContentSize = CGSize(width: view.frame.width, height: view.frame.width)
                if preferredContentSize != self.preferredContentSize {
                    self.preferredContentSize = preferredContentSize
                }
            }
        }

        let viewController = SquareViewController()
        let hostContainer = ModalHostContainerViewController(content: viewController)

        var axisSize: CGFloat = 100
        hostContainer.view.frame.size = .init(width: axisSize, height: 0)
        hostContainer.view.layoutIfNeeded()
        XCTAssertEqual(hostContainer.preferredContentSize, CGSize(width: axisSize, height: axisSize))

        axisSize = 200
        hostContainer.view.frame.size = .init(width: axisSize, height: 0)
        hostContainer.view.layoutIfNeeded()
        XCTAssertEqual(hostContainer.preferredContentSize, CGSize(width: axisSize, height: axisSize))
    }

    func test_supportedInterfaceOrientationSource() {
        let rootLandscapeLeftViewController = TestSupportedInterfaceOrientationsViewController(
            supportedOrientations: .landscapeLeft
        )

        let hostContainer = ModalHostContainerViewController(content: rootLandscapeLeftViewController)

        XCTAssertEqual(hostContainer.supportedInterfaceOrientations, .landscapeLeft)

        var lifetimes: [ModalLifetime] = []

        func present(
            _ viewController: UIViewController,
            providesValues: Bool
        ) {
            lifetimes.append(rootLandscapeLeftViewController.modalPresenter.present(
                viewController,
                style: .testFull(viewControllerContainmentPreferences: providesValues ? .provideAll : .provideNone)
            ))

            // Apply presentation.
            hostContainer.view.layoutIfNeeded()
        }

        let landscapeRightViewController = TestSupportedInterfaceOrientationsViewController(
            supportedOrientations: .landscapeRight
        )
        present(landscapeRightViewController, providesValues: false)
        XCTAssertEqual(hostContainer.supportedInterfaceOrientations, .landscapeLeft)

        let portraitViewController = TestSupportedInterfaceOrientationsViewController(
            supportedOrientations: .portrait
        )
        present(portraitViewController, providesValues: true)
        XCTAssertEqual(hostContainer.supportedInterfaceOrientations, .portrait)

        let portraitUpsideDownViewController = TestSupportedInterfaceOrientationsViewController(
            supportedOrientations: .portraitUpsideDown
        )
        present(portraitUpsideDownViewController, providesValues: false)
        XCTAssertEqual(hostContainer.supportedInterfaceOrientations, .portrait)
    }

    func test_aggregation() {
        let content = UIViewController()
        let presented = UIViewController()

        let host = ModalHostContainerViewController(
            content: content,
            toastContainerStyle: .fixture,
            presentationFilter: nil
        )

        let lifetime = content.modalPresenter.present(presented, style: .testFull())
        let modalList = host.aggregateModals()

        // a host with no filter should suppress any modal from aggregating up
        XCTAssert(modalList.modals.isEmpty)

        lifetime.dismiss()
    }

    func test_filteredAggregation() {
        let content = DirectPresentingViewController(name: "content")

        let forwarded = DirectPresentingViewController(name: "forwarded")
        let nestedInForwarded = DirectPresentingViewController(name: "nested-in-forwarded")

        let filtered = DirectPresentingViewController(name: "filtered")
        let nestedInFiltered = DirectPresentingViewController(name: "nested-in-filtered")

        let host = ModalHostContainerViewController(
            content: content,
            toastContainerStyle: .fixture,
            presentationFilter: .containsUniqueKey(TestModalInfoKey.self)
        )
        let superHost = ModalHostContainerViewController(content: host)

        content.present(viewController: forwarded)
        forwarded.present(viewController: nestedInForwarded)

        content.present(viewController: filtered, filter: true)
        filtered.present(viewController: nestedInFiltered)

        // let the presentation VC layout to set up children
        show(vc: superHost) { superHost in
            let modalList = host.aggregateModals()

            XCTAssertEqual(
                modalList.modals.map(\.viewController),
                [forwarded, nestedInForwarded, nestedInFiltered]
            )
        }
    }
}

private enum TestModalInfoKey: UniqueModalInfoKey {}

/// Directly implements `aggregateModals` to avoid all the assertions around presentation with
/// `TrampolineModalPresenter`.
private class DirectPresentingViewController: UIViewController {
    var presenting: [(UIViewController, Bool)] = []
    var name: String

    init(name: String) {
        self.name = name
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(viewController: UIViewController, filter: Bool = false) {
        presenting.append((viewController, filter))
    }

    override func aggregateModals() -> ModalList {
        ModalList(
            modals: presenting.flatMap { viewController, filter in
                let modal = PresentableModal(
                    viewController: viewController,
                    presentationStyle: TestFullScreenStyle(),
                    info: filter ? .empty().setting(uniqueKey: TestModalInfoKey.self) : .empty(),
                    onDidPresent: nil
                )

                return [modal] + viewController.aggregateModals().modals
            }
        )
    }

    override var description: String {
        name
    }
}
