import Modals
import TestingSupport
import ViewEnvironment
import WorkflowUI
import XCTest
@_spi(WorkflowModalsImplementation) import WorkflowModals

final class ModalContainerTests: XCTestCase {

    func test_modal_updates() throws {

        let modalScreen = ModalContainer(
            base: EmptyScreen(),
            modals: [
                Modal(
                    key: "first-modal",
                    style: FullScreenModalStyle(
                        environmentCustomization: { $0[TestKey.self] = true }
                    ),
                    content: EmptyScreen()
                ),
            ]
        )

        let description = modalScreen.viewControllerDescription(environment: .empty)
        let viewController = try XCTUnwrap(description.buildViewController() as? AnyModalToastContainerViewController)

        XCTAssertFalse(viewController.isViewLoaded)

        viewController.view.layoutIfNeeded()

        do {
            // The initial modal should be aggregated
            let modalList = viewController.aggregateModals()
            XCTAssertEqual(modalList.modals.count, 1)

            // Modal content should respect environment customizations defined on the style
            let modal = try XCTUnwrap(modalList.modals.first)
            XCTAssertTrue(modal.viewController.environment[TestKey.self])
        }

        do {
            // Adding a new modal should add a new modal to the list
            let newScreen = ModalContainer(
                base: EmptyScreen(),
                modals: [
                    Modal(
                        key: "first-modal",
                        style: FullScreenModalStyle(),
                        content: EmptyScreen()
                    ),
                    Modal(
                        key: "second-modal",
                        style: FullScreenModalStyle(),
                        content: EmptyScreen()
                    ),
                ]
            )

            newScreen.viewControllerDescription(environment: .empty)
                .update(viewController: viewController)

            XCTAssertEqual(viewController.aggregateModals().modals.count, 2)
        }

        do {
            // Updating a modal with the same key should reuse the existing view controller;
            // changing the key should result in a new view controller
            let newScreen = ModalContainer(
                base: EmptyScreen(),
                modals: [
                    Modal(
                        key: "first-modal",
                        style: FullScreenModalStyle(),
                        content: EmptyScreen()
                    ),
                    Modal(
                        key: "new-second-modal",
                        style: FullScreenModalStyle(),
                        content: EmptyScreen()
                    ),
                ]
            )

            let existingFirstViewController = viewController.aggregateModals().modals[0].viewController
            let existingSecondViewController = viewController.aggregateModals().modals[1].viewController


            newScreen.viewControllerDescription(environment: .empty)
                .update(viewController: viewController)

            XCTAssertEqual(
                viewController.aggregateModals().modals[0].viewController,
                existingFirstViewController
            )

            XCTAssertNotEqual(
                viewController.aggregateModals().modals[1].viewController,
                existingSecondViewController
            )
        }

        do {
            // Removing modals should remove them from the array
            let newScreen = ModalContainer<EmptyScreen, EmptyScreen>(
                base: EmptyScreen(),
                modals: []
            )

            newScreen.viewControllerDescription(environment: .empty)
                .update(viewController: viewController)

            XCTAssertTrue(viewController.aggregateModals().modals.isEmpty)
        }
    }

    func test_modal_host_is_updated() throws {
        class HostViewController: UIViewController, ModalHost {

            var updateModalsCount = 0
            var aggregatedModalCount = 0

            func setNeedsModalUpdate() {
                updateModalsCount += 1
                aggregatedModalCount = aggregateModals().modals.count
            }
        }

        let modalScreen = ModalContainer(
            base: EmptyScreen(),
            modals: [
                Modal(
                    key: "first-modal",
                    style: FullScreenModalStyle(),
                    content: EmptyScreen()
                ),
            ]
        )

        let description = modalScreen.viewControllerDescription(environment: .empty)
        let viewController = try XCTUnwrap(description.buildViewController() as? AnyModalToastContainerViewController)

        let host = HostViewController()
        host.addChild(viewController)
        host.view.addSubview(viewController.view)
        viewController.didMove(toParent: host)

        show(vc: host) { host in

            viewController.view.layoutIfNeeded()

            do {
                // The modal host should be updated
                XCTAssertEqual(host.updateModalsCount, 1)
                XCTAssertEqual(host.aggregatedModalCount, 1)
            }

            do {
                // Updating the screen should update the host again
                let newScreen = ModalContainer(
                    base: EmptyScreen(),
                    modals: [
                        Modal(
                            key: "first-modal",
                            style: FullScreenModalStyle(),
                            content: EmptyScreen()
                        ),
                        Modal(
                            key: "second-modal",
                            style: FullScreenModalStyle(),
                            content: EmptyScreen()
                        ),
                    ]
                )


                newScreen.viewControllerDescription(environment: .empty)
                    .update(viewController: viewController)

                // The modal system async updates using the view layout pass
                viewController.view.layoutIfNeeded()

                XCTAssertEqual(host.updateModalsCount, 2)
                XCTAssertEqual(host.aggregatedModalCount, 2)

                // Check that the view controller notifies the host with no modals when removed
                viewController.willMove(toParent: nil)
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()

                XCTAssertEqual(host.updateModalsCount, 3)
                XCTAssertEqual(host.aggregatedModalCount, 0)
            }
        }
    }
}

extension ModalContainerTests {

    fileprivate struct TestKey: ViewEnvironmentKey {

        static var defaultValue = false
    }
}
