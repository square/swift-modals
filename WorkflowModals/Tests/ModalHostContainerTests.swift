import Modals
import TestingSupport
import UIKit
import WorkflowUI
import XCTest
@testable import WorkflowModals

class ModalHostContainerTests: XCTestCase {

    func test_modals_are_presented() {
        let modalScreen = ModalContainer(
            base: EmptyScreen(),
            modals: [
                Modal(
                    key: "original-modal",
                    style: FullScreenModalStyle(),
                    content: EmptyScreen()
                ),
            ]
        )

        let viewController = ModalHostContainer.ViewController(
            screen: .init(
                content: modalScreen,
                toastContainerStyle: .fixture
            ),
            environment: .empty
        )

        let presenter = viewController.modalPresentationController

        show(vc: viewController) { viewController in

            viewController.view.layoutIfNeeded()

            do {
                // Initial modal should be presented
                XCTAssertEqual(viewController.modalPresentationController.presentedViewControllers.count, 1)
            }

            do {
                // Changing the modal should change the presented view controller
                let originalViewController = viewController.modalPresentationController.presentedViewControllers[0]

                let newScreen = ModalContainer(
                    base: EmptyScreen(),
                    modals: [
                        Modal(
                            key: "new-modal",
                            style: FullScreenModalStyle(),
                            content: EmptyScreen()
                        ),
                    ]
                )

                viewController.update(
                    screen: .init(
                        content: newScreen,
                        toastContainerStyle: .fixture
                    )
                )
                viewController.view.layoutIfNeeded()


                XCTAssertNotEqual(
                    originalViewController,
                    presenter.presentedViewControllers[0]
                )

                XCTAssertEqual(presenter.presentedViewControllers.count, 1)
            }

            do {
                // Updating modal with the same key should not change the presented view controller
                let originalViewController = viewController.modalPresentationController.presentedViewControllers[0]

                let newScreen = ModalContainer(
                    base: EmptyScreen(),
                    modals: [
                        Modal(
                            key: "new-modal",
                            style: FullScreenModalStyle(),
                            content: EmptyScreen()
                        ),
                    ]
                )

                viewController.update(
                    screen: .init(
                        content: newScreen,
                        toastContainerStyle: .fixture
                    )
                )
                viewController.view.layoutIfNeeded()

                XCTAssertEqual(
                    originalViewController,
                    presenter.presentedViewControllers[0]
                )

                XCTAssertEqual(presenter.presentedViewControllers.count, 1)
            }

            do {
                // Multiple modals should get presented
                let newScreen = ModalContainer(
                    base: EmptyScreen(),
                    modals: [
                        Modal(
                            key: "new-modal",
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

                viewController.update(
                    screen: .init(
                        content: newScreen,
                        toastContainerStyle: .fixture
                    )
                )
                viewController.view.layoutIfNeeded()

                XCTAssertEqual(presenter.presentedViewControllers.count, 2)
            }

            do {
                // Removing modals should remove them from being presented
                let newScreen = ModalContainer<EmptyScreen, EmptyScreen>(
                    base: EmptyScreen(),
                    modals: []
                )

                viewController.update(
                    screen: .init(
                        content: newScreen,
                        toastContainerStyle: .fixture
                    )
                )
                viewController.view.layoutIfNeeded()

                XCTAssertTrue(presenter.presentedViewControllers.isEmpty)
            }
        }
    }

    func test_toasts_are_presented() {
        let toastScreen = ToastContainer(
            base: EmptyScreen(),
            toasts: [
                Toast(
                    key: "original-toast",
                    style: ToastPresentationStyleFixture(),
                    content: EmptyScreen(),
                    accessibilityAnnouncement: "Presented toast."
                ),
            ]
        )

        let viewController = ModalHostContainer.ViewController(
            screen: .init(
                content: toastScreen,
                toastContainerStyle: .fixture
            ),
            environment: .empty
        )

        let presenter = viewController.toastPresentationController

        show(vc: viewController) { viewController in

            viewController.view.layoutIfNeeded()

            do {
                // Initial toast should be presented
                XCTAssertEqual(presenter.presentedViewControllers.count, 1)
            }

            do {
                // Changing the toast should change the presented view controller
                let originalViewController = presenter.presentedViewControllers[0]

                let newScreen = ToastContainer(
                    base: EmptyScreen(),
                    toasts: [
                        Toast(
                            key: "new-toast",
                            style: ToastPresentationStyleFixture(),
                            content: EmptyScreen(),
                            accessibilityAnnouncement: "Presented toast."
                        ),
                    ]
                )

                viewController.update(
                    screen: .init(
                        content: newScreen,
                        toastContainerStyle: .fixture
                    )
                )
                viewController.view.layoutIfNeeded()


                XCTAssertNotEqual(
                    originalViewController,
                    presenter.presentedViewControllers[0]
                )

                XCTAssertEqual(presenter.presentedViewControllers.count, 1)
            }

            do {
                // Updating toast with the same key should not change the presented view controller
                let originalViewController = presenter.presentedViewControllers[0]

                let newScreen = ToastContainer(
                    base: EmptyScreen(),
                    toasts: [
                        Toast(
                            key: "new-toast",
                            style: ToastPresentationStyleFixture(),
                            content: EmptyScreen(),
                            accessibilityAnnouncement: "Presented toast."
                        ),
                    ]
                )

                viewController.update(
                    screen: .init(
                        content: newScreen,
                        toastContainerStyle: .fixture
                    )
                )
                viewController.view.layoutIfNeeded()

                XCTAssertEqual(
                    originalViewController,
                    presenter.presentedViewControllers[0]
                )

                XCTAssertEqual(presenter.presentedViewControllers.count, 1)
            }

            do {
                // Multiple toasts should get presented
                let newScreen = ToastContainer(
                    base: EmptyScreen(),
                    toasts: [
                        Toast(
                            key: "new-toast",
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

                viewController.update(
                    screen: .init(
                        content: newScreen,
                        toastContainerStyle: .fixture
                    )
                )
                viewController.view.layoutIfNeeded()

                XCTAssertEqual(presenter.presentedViewControllers.count, 2)
            }

            do {
                // Removing toasts should remove them from being presented
                let newScreen = ToastContainer<EmptyScreen, EmptyScreen>(
                    base: EmptyScreen(),
                    toasts: []
                )

                viewController.update(
                    screen: .init(
                        content: newScreen,
                        toastContainerStyle: .fixture
                    )
                )
                viewController.view.layoutIfNeeded()

                XCTAssertTrue(presenter.presentedViewControllers.isEmpty)
            }
        }
    }

    func test_unique_key_presentation_filter() {
        enum PresentedModal: UniqueModalInfoKey {}
        enum ForwardedModal: UniqueModalInfoKey {}

        final class ParentController: UIViewController, ModalHost {
            var updates: Int = 0

            func setNeedsModalUpdate() {
                updates += 1
            }
        }

        let modalScreen = ModalContainer(
            base: EmptyScreen(),
            modals: [
                Modal(
                    key: "presented-modal",
                    style: FullScreenModalStyle(),
                    info: .empty().setting(uniqueKey: PresentedModal.self),
                    content: ModalContainer(
                        base: EmptyScreen(),
                        modals: [
                            Modal(
                                key: "nested-in-presented",
                                style: FullScreenModalStyle(),
                                info: .empty().setting(uniqueKey: ForwardedModal.self),
                                screen: EmptyScreen()
                            ),
                        ]
                    )
                ),
                Modal(
                    key: "forwarded-modal",
                    style: FullScreenModalStyle(),
                    info: .empty().setting(uniqueKey: ForwardedModal.self),
                    content: ModalContainer(
                        base: EmptyScreen(),
                        modals: [
                            Modal(
                                key: "nested-in-forwarded",
                                style: FullScreenModalStyle(),
                                info: .empty().setting(uniqueKey: ForwardedModal.self),
                                screen: EmptyScreen()
                            ),
                        ]
                    )
                ),
            ]
        )

        let parent = ParentController()

        let child = ModalHostContainer.ViewController(
            screen: .init(
                content: modalScreen,
                toastContainerStyle: .fixture,
                presentationFilter: .containsUniqueKey(PresentedModal.self)
            ),
            environment: .empty
        )

        parent.addChild(child)

        do {
            child.view.layoutIfNeeded()

            // Presented modal is removed from aggregation. Forwarded modals remain.
            let aggregated = child.aggregateModals().modals
            XCTAssertEqual(aggregated.count, 3)
            XCTAssert(aggregated.allSatisfy { $0.info.contains(ForwardedModal.self) })

            // Parent update was invoked at least once. Aggregation includes the forwarded modals.
            XCTAssertGreaterThanOrEqual(parent.updates, 1)
            let parentAggregated = parent.aggregateModals().modals
            XCTAssertEqual(parentAggregated.count, 3)
            XCTAssert(parentAggregated.allSatisfy { $0.info.contains(ForwardedModal.self) })

            // Child has presented only its filtered modal.
            XCTAssertEqual(child.modalPresentationController.presentedViewControllers.count, 1)
        }
    }

    func test_preferredContentSize() {
        struct TestScreen: Screen {

            func viewControllerDescription(environment: ViewEnvironment) -> ViewControllerDescription {
                SquareViewController.description(for: self, environment: environment)
            }

            class SquareViewController: ScreenViewController<TestScreen> {
                override func viewDidLayoutSubviews() {
                    super.viewDidLayoutSubviews()

                    let preferredContentSize = CGSize(width: view.frame.width, height: view.frame.width)
                    if preferredContentSize != self.preferredContentSize {
                        self.preferredContentSize = preferredContentSize
                    }
                }
            }
        }

        let hostContainer = ModalHostContainer.ViewController(
            screen: .init(
                content: TestScreen(),
                toastContainerStyle: .fixture
            ),
            environment: .empty
        )

        var axisSize: CGFloat = 100
        hostContainer.view.frame.size = .init(width: axisSize, height: 0)
        hostContainer.view.layoutIfNeeded()
        XCTAssertEqual(hostContainer.preferredContentSize, CGSize(width: axisSize, height: axisSize))

        axisSize = 200
        hostContainer.view.frame.size = .init(width: axisSize, height: 0)
        hostContainer.view.layoutIfNeeded()
        XCTAssertEqual(hostContainer.preferredContentSize, CGSize(width: axisSize, height: axisSize))
    }
}
