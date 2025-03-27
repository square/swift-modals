import Modals
import TestingSupport
import WorkflowUI
import XCTest

@_spi(WorkflowModalsImplementation) import WorkflowModals


class ToastContainerTests: XCTestCase {

    func test_toast_updates() throws {

        let toastScreen = ToastContainer(
            base: EmptyScreen(),
            toasts: [
                Toast(
                    key: "first-toast",
                    style: ToastPresentationStyleFixture(),
                    content: EmptyScreen(),
                    accessibilityAnnouncement: "Presented toast."
                ),
            ]
        )

        let description = toastScreen.viewControllerDescription(environment: .empty)
        let viewController = try XCTUnwrap(description.buildViewController() as? AnyModalToastContainerViewController)

        XCTAssertFalse(viewController.isViewLoaded)

        viewController.view.layoutIfNeeded()

        do {
            // The initial toast should be aggregated
            XCTAssertEqual(viewController.aggregateModals().toasts.count, 1)
        }

        do {
            // Adding a new toast should add a new toast to the list
            let newScreen = ToastContainer(
                base: EmptyScreen(),
                toasts: [
                    Toast(
                        key: "first-toast",
                        style: ToastPresentationStyleFixture(),
                        content: EmptyScreen(),
                        accessibilityAnnouncement: "Presented toast."
                    ),
                    Toast(
                        key: "second-toast",
                        style: ToastPresentationStyleFixture(),
                        content: EmptyScreen(),
                        accessibilityAnnouncement: "Presented toast."
                    ),
                ]
            )

            newScreen.viewControllerDescription(environment: .empty)
                .update(viewController: viewController)

            XCTAssertEqual(viewController.aggregateModals().toasts.count, 2)
        }

        do {
            // Updating a toast with the same key should reuse the existing view controller;
            // changing the key should result in a new view controller
            let newScreen = ToastContainer(
                base: EmptyScreen(),
                toasts: [
                    Toast(
                        key: "first-toast",
                        style: ToastPresentationStyleFixture(),
                        content: EmptyScreen(),
                        accessibilityAnnouncement: "Presented toast."
                    ),
                    Toast(
                        key: "new-second-toast",
                        style: ToastPresentationStyleFixture(),
                        content: EmptyScreen(),
                        accessibilityAnnouncement: "Presented toast."
                    ),
                ]
            )

            let existingFirstViewController = viewController.aggregateModals().toasts[0].viewController
            let existingSecondViewController = viewController.aggregateModals().toasts[1].viewController

            newScreen.viewControllerDescription(environment: .empty)
                .update(viewController: viewController)

            XCTAssertEqual(
                viewController.aggregateModals().toasts[0].viewController,
                existingFirstViewController
            )

            XCTAssertNotEqual(
                viewController.aggregateModals().toasts[1].viewController,
                existingSecondViewController
            )
        }

        do {
            // Removing toasts should remove them from the array
            let newScreen = ToastContainer<EmptyScreen, EmptyScreen>(
                base: EmptyScreen(),
                toasts: []
            )

            newScreen.viewControllerDescription(environment: .empty)
                .update(viewController: viewController)

            XCTAssertTrue(viewController.aggregateModals().toasts.isEmpty)
        }
    }
}

extension ScreenViewController {
    private var viewEnvironment: ViewEnvironment { environment }
}
