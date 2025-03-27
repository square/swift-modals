import Modals
import UIKit

extension ModalHostContainerViewController {

    public convenience init(
        content: UIViewController,
        shouldPassthroughToasts: Bool = true
    ) {
        self.init(
            content: content,
            toastContainerStyle: .fixture,
            shouldPassthroughToasts: shouldPassthroughToasts
        )
    }
}
