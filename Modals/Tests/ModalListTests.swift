import XCTest

@testable import Modals


class ModalListTests: XCTestCase {

    func test_addition() {
        let a = ModalList(modals: [.a], toasts: [.a], toastSafeAreaAnchors: [.a])
        let b = ModalList(modals: [.b], toasts: [.b], toastSafeAreaAnchors: [.b])

        let expected = ModalList(
            modals: [.a, .b],
            toasts: [.a, .b],
            toastSafeAreaAnchors: [.a, .b]
        )
        XCTAssertEqual(a + b, expected)
    }

    func test_appending() {
        let a = ModalList(modals: [.a], toasts: [.a], toastSafeAreaAnchors: [.a])

        let result = a.appending(
            modals: [.b],
            toasts: [.b],
            toastSafeAreaAnchors: [.b]
        )
        let expected = ModalList(
            modals: [.a, .b],
            toasts: [.a, .b],
            toastSafeAreaAnchors: [.a, .b]
        )
        XCTAssertEqual(result, expected)
    }
}

extension ModalList {
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ModalList else {
            return false
        }

        return modals.count == other.modals.count
            && zip(modals, other.modals).allSatisfy { $0 === $1 }
            && toasts.count == other.toasts.count
            && zip(toasts, other.toasts).allSatisfy { $0 === $1 }
            && toastSafeAreaAnchors.count == other.toastSafeAreaAnchors.count
            && zip(toastSafeAreaAnchors, other.toastSafeAreaAnchors).allSatisfy { $0 === $1 }
    }
}

extension PresentableModal {
    fileprivate static let a = PresentableModal(
        viewController: UIViewController(),
        presentationStyle: TestFullScreenStyle(),
        info: .empty(),
        onDidPresent: nil
    )

    fileprivate static let b = PresentableModal(
        viewController: UIViewController(),
        presentationStyle: TestFullScreenStyle(),
        info: .empty(),
        onDidPresent: nil
    )
}


extension PresentableToast {
    fileprivate static let a = PresentableToast(
        viewController: UIViewController(),
        presentationStyle: TestToastPresentationStyle(),
        accessibilityAnnouncement: "a"
    )

    fileprivate static let b = PresentableToast(
        viewController: UIViewController(),
        presentationStyle: TestToastPresentationStyle(),
        accessibilityAnnouncement: "b"
    )
}

extension ToastSafeAreaAnchor {
    fileprivate static let a = ToastSafeAreaAnchor(onChange: {})

    fileprivate static let b = ToastSafeAreaAnchor(onChange: {})
}
