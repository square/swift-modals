import Modals
import TestingSupport
import ViewEnvironment
import WorkflowUI
import XCTest
@_spi(WorkflowModalsImplementation) import WorkflowModals

final class ModalContainerTests: XCTestCase {

    func test_removal_callback_survives_mapping_type_erasure_and_controller_reuse() throws {
        func screen(onDidRemove: (() -> Void)?) -> ModalContainer<EmptyScreen, AnyScreen> {
            ModalContainer(
                base: EmptyScreen(),
                modals: [Modal(
                    key: "modal",
                    style: FullScreenModalStyle(),
                    onDidRemove: onDidRemove,
                    content: EmptyScreen()
                ).map { $0.asAnyScreen() }]
            )
        }

        var callbacks: [String] = []
        let description = screen { callbacks.append("original") }.viewControllerDescription(environment: .empty)
        let container = try XCTUnwrap(description.buildViewController() as? AnyModalToastContainerViewController)
        container.view.layoutIfNeeded()

        let presenter = ModalPresentationViewController(content: UIViewController())
        let original = try XCTUnwrap(container.aggregateModals().modals.first)
        presenter.update(modals: [original])

        screen { callbacks.append("updated") }.viewControllerDescription(environment: .empty)
            .update(viewController: container)
        container.view.layoutIfNeeded()
        let updated = try XCTUnwrap(container.aggregateModals().modals.first)
        XCTAssertTrue(original.viewController === updated.viewController)
        presenter.update(modals: [updated])
        XCTAssertTrue(callbacks.isEmpty)
        presenter.update(modals: [])
        XCTAssertEqual(callbacks, ["updated"])

        presenter.update(modals: [updated])
        screen(onDidRemove: nil).viewControllerDescription(environment: .empty)
            .update(viewController: container)
        container.view.layoutIfNeeded()
        presenter.update(modals: container.aggregateModals().modals)
        presenter.update(modals: [])
        XCTAssertEqual(callbacks, ["updated"])
    }

    func test_removal_callbacks_for_duplicate_keys_follow_reused_controllers() throws {
        func screen(callbacks: [() -> Void]) -> ModalContainer<EmptyScreen, EmptyScreen> {
            ModalContainer(
                base: EmptyScreen(),
                modals: callbacks.map { callback in
                    Modal(key: "shared", style: FullScreenModalStyle(), onDidRemove: callback, content: EmptyScreen())
                }
            )
        }

        var callbacks: [String] = []
        let description = screen(callbacks: [{ callbacks.append("first") }, { callbacks.append("second") }])
            .viewControllerDescription(environment: .empty)
        let container = try XCTUnwrap(description.buildViewController() as? AnyModalToastContainerViewController)
        container.view.layoutIfNeeded()
        let originalControllers = container.aggregateModals().modals.map(\.viewController)
        let presenter = ModalPresentationViewController(content: UIViewController())
        presenter.update(modals: container.aggregateModals().modals)

        screen(callbacks: [{ callbacks.append("updated first") }]).viewControllerDescription(environment: .empty)
            .update(viewController: container)
        container.view.layoutIfNeeded()
        let remaining = container.aggregateModals().modals
        XCTAssertEqual(remaining.map(\.viewController), [originalControllers[0]])
        presenter.update(modals: remaining)
        XCTAssertEqual(callbacks, ["second"])
        presenter.update(modals: [])
        XCTAssertEqual(callbacks, ["second", "updated first"])
    }

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

    func test_modal_host_update_defers_when_view_has_window_without_parent() throws {
        class HostViewController: UIViewController, ModalHost {

            var updateModalsCount = 0
            var aggregatedModalCount = 0

            func setNeedsModalUpdate() {
                updateModalsCount += 1
                aggregatedModalCount = aggregateModals().modals.count
            }
        }

        let modalScreen = ModalContainer<EmptyScreen, EmptyScreen>(
            base: EmptyScreen(),
            modals: []
        )

        let description = modalScreen.viewControllerDescription(environment: .empty)
        let viewController = try XCTUnwrap(description.buildViewController() as? AnyModalToastContainerViewController)

        let host = HostViewController()

        show(vc: host) { host in
            viewController.view.frame = host.view.bounds
            host.view.addSubview(viewController.view)

            XCTAssertNil(viewController.parent)
            XCTAssertNotNil(viewController.view.window)

            let updatedScreen = ModalContainer(
                base: EmptyScreen(),
                modals: [
                    Modal(
                        key: "first-modal",
                        style: FullScreenModalStyle(),
                        content: EmptyScreen()
                    ),
                ]
            )

            updatedScreen.viewControllerDescription(environment: .empty)
                .update(viewController: viewController)
            viewController.view.layoutIfNeeded()

            XCTAssertEqual(host.updateModalsCount, 0)

            viewController.view.removeFromSuperview()
            host.addChild(viewController)
            host.view.addSubview(viewController.view)
            viewController.didMove(toParent: host)

            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()

            XCTAssertEqual(host.updateModalsCount, 1)
            XCTAssertEqual(host.aggregatedModalCount, 1)

            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
    }
}

extension ModalContainerTests {

    fileprivate struct TestKey: ViewEnvironmentKey {

        static var defaultValue = false
    }
}
