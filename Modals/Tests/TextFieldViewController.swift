import UIKit

class TextFieldViewController: UIViewController {
    let textField = TestTextField()

    var didBecomeFirstResponder: (() -> Void)? {
        get { textField.didBecomeFirstResponder }
        set { textField.didBecomeFirstResponder = newValue }
    }

    var didResignFirstResponder: (() -> Void)? {
        get { textField.didResignFirstResponder }
        set { textField.didResignFirstResponder = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(textField)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textField.frame = view.bounds
    }
}

class TestTextField: UITextField {
    var didBecomeFirstResponder: (() -> Void)? = nil
    var didResignFirstResponder: (() -> Void)? = nil

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        if became {
            didBecomeFirstResponder?()
        }
        return became
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned {
            didResignFirstResponder?()
        }
        return resigned
    }
}
