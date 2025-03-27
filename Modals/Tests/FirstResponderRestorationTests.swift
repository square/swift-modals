import TestingSupport
import XCTest
@testable import Modals

class FirstResponderRestorationTests: XCTestCase {

    func test_base_content_first_responder_is_restored() {
        let baseViewController = TextFieldViewController()

        let modalHostViewController = ModalHostContainerViewController(
            content: baseViewController,
            toastContainerStyle: .fixture
        )
        var lifetime: ModalLifetime?

        show(vc: modalHostViewController) { _ in
            baseViewController.textField.becomeFirstResponder()

            let presentedViewController = UIViewController()
            let presented = expectation(description: "presented")

            let becameFirstResponder = expectation(description: "becameFirstResponder")
            baseViewController.didBecomeFirstResponder = {
                becameFirstResponder.fulfill()
            }

            lifetime = baseViewController.modalPresenter.present(
                presentedViewController,
                style: .init(TestFullScreenStyle()),
                info: .empty()
            ) {
                presented.fulfill()
            }
            wait(for: [presented], timeout: 5)

            XCTAssertNil(UIResponder.currentFirstResponder)

            lifetime?.dismiss()

            wait(for: [becameFirstResponder], timeout: 5)
        }
    }

    func test_base_content_first_responder_is_not_restored_when_previously_restored() {
        let baseViewController = TextFieldViewController()
        let modalHostViewController = ModalHostContainerViewController(
            content: baseViewController,
            toastContainerStyle: .fixture
        )
        var lifetime: ModalLifetime?

        show(vc: modalHostViewController) { _ in
            baseViewController.textField.becomeFirstResponder()

            do {
                let presentedViewController = UIViewController()
                let presented = expectation(description: "presented")

                let becameFirstResponder = expectation(description: "becameFirstResponder")
                baseViewController.didBecomeFirstResponder = {
                    becameFirstResponder.fulfill()
                }

                lifetime = baseViewController.modalPresenter.present(
                    presentedViewController,
                    style: .init(TestFullScreenStyle()),
                    info: .empty()
                ) {
                    presented.fulfill()
                }
                wait(for: [presented], timeout: 5)

                XCTAssertNil(UIResponder.currentFirstResponder)

                lifetime?.dismiss()

                wait(for: [becameFirstResponder], timeout: 5)
            }

            baseViewController.textField.resignFirstResponder()

            do {
                let presentedViewController = TextFieldViewController()
                let presented = expectation(description: "presented")

                lifetime = baseViewController.modalPresenter.present(
                    presentedViewController,
                    style: .init(TestFullScreenStyle()),
                    info: .empty()
                ) {
                    presented.fulfill()
                }
                wait(for: [presented], timeout: 5)

                XCTAssertNil(UIResponder.currentFirstResponder)

                let presentedResigned = expectation(description: "presentedResigned")
                presentedViewController.textField.becomeFirstResponder()
                presentedViewController.didResignFirstResponder = {
                    presentedResigned.fulfill()
                }

                lifetime?.dismiss()

                wait(for: [presentedResigned], timeout: 5)

                XCTAssertNil(UIResponder.currentFirstResponder)
            }
        }
    }

    func test_modal_first_responder_is_restored() {
        let baseViewController = UIViewController()
        let modalHostViewController = ModalHostContainerViewController(
            content: baseViewController,
            toastContainerStyle: .fixture
        )
        var firstLifetime: ModalLifetime?
        var secondLifetime: ModalLifetime?

        show(vc: modalHostViewController) { _ in
            let firstPresentedViewController = TextFieldViewController()
            let firstPresented = expectation(description: "firstPresented")

            firstLifetime = baseViewController.modalPresenter.present(
                firstPresentedViewController,
                style: .init(TestFullScreenStyle()),
                info: .empty()
            ) {
                firstPresented.fulfill()
            }
            wait(for: [firstPresented], timeout: 5)

            firstPresentedViewController.textField.becomeFirstResponder()

            let secondPresented = expectation(description: "secondPresented")
            secondLifetime = firstPresentedViewController.modalPresenter.present(
                UIViewController(),
                style: .init(TestFullScreenStyle()),
                info: .empty()
            ) {
                secondPresented.fulfill()
            }

            wait(for: [secondPresented], timeout: 5)
            XCTAssertNil(UIResponder.currentFirstResponder)

            let becameFirstResponder = expectation(description: "becameFirstResponder")
            firstPresentedViewController.didBecomeFirstResponder = {
                becameFirstResponder.fulfill()
            }

            secondLifetime?.dismiss()

            wait(for: [becameFirstResponder], timeout: 5)
            XCTAssertEqual(UIResponder.currentFirstResponder, firstPresentedViewController.textField)

            let resignedFirstResponder = expectation(description: "resignedFirstResponder")
            firstPresentedViewController.didResignFirstResponder = {
                resignedFirstResponder.fulfill()
            }

            firstLifetime?.dismiss()

            wait(for: [resignedFirstResponder], timeout: 5)
            XCTAssertNil(UIResponder.currentFirstResponder)
        }
    }
}
