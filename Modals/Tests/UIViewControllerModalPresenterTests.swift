import ViewEnvironment
@_spi(ViewEnvironmentWiring) import ViewEnvironmentUI
import XCTest

@testable import Modals


final class UIViewControllerModalPresenterTests: XCTestCase {

    func test_modal_content_environment_customization() throws {
        let root = UIViewController()

        // Embed in modal host just to avoid hitting missing host assertions.
        let host = ModalHostContainerViewController(content: root)

        var environmentUpdates: [ViewEnvironment] = []
        let content = EnvironmentObservingViewController(
            onEnvironmentDidChange: { environmentUpdates.append($0) }
        )
        let lifetime = root.modalPresenter.present(
            content,
            style: .testFull(environmentCustomization: {
                $0[TestKey.self] = true
            })
        )

        do {
            let modalList = root.aggregateModals()
            XCTAssertEqual(modalList.modals.count, 1)
            let modal = try XCTUnwrap(modalList.modals.first)
            XCTAssertEqual(modal.viewController, content)

            XCTAssertEqual(environmentUpdates.count, 1)
            let environment = try XCTUnwrap(environmentUpdates.first)

            XCTAssertTrue(environment[TestKey.self])
            XCTAssertTrue(content.environment[TestKey.self])
        }

        withExtendedLifetime(lifetime) {}
        withExtendedLifetime(host) {}
    }
}

extension UIViewControllerModalPresenterTests {

    fileprivate final class EnvironmentObservingViewController: UIViewController, ViewEnvironmentObserving {

        let onEnvironmentDidChange: (ViewEnvironment) -> Void

        init(
            onEnvironmentDidChange: @escaping (ViewEnvironment) -> Void = { _ in }
        ) {
            self.onEnvironmentDidChange = onEnvironmentDidChange
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError() }

        func environmentDidChange() {
            onEnvironmentDidChange(environment)
        }
    }

    fileprivate struct TestKey: ViewEnvironmentKey {

        static var defaultValue = false
    }
}
