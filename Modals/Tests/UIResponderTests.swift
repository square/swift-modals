import TestingSupport
import XCTest
@testable import Modals

class UIResponderTests: XCTestCase {

    func test_current_first_responder() {
        let viewController = TextFieldViewController()
        show(vc: viewController) { viewController in
            viewController.textField.becomeFirstResponder()
            XCTAssertEqual(viewController.textField, UIResponder.currentFirstResponder)
            viewController.textField.resignFirstResponder()
            XCTAssertNil(UIResponder.currentFirstResponder)
        }
    }

    func test_resign_current_first_responder() {
        let viewController = TextFieldViewController()
        show(vc: viewController) { viewController in
            viewController.textField.becomeFirstResponder()
            XCTAssertTrue(viewController.textField.isFirstResponder)
            UIResponder.resignCurrentFirstResponder()
            XCTAssertFalse(viewController.textField.isFirstResponder)
        }
    }

    func test_is_descendant() {
        let viewController = TextFieldViewController()
        show(vc: viewController) { viewController in
            XCTAssertTrue(viewController.textField.isDescendant(of: viewController))
        }
    }
}
