import UIKit

extension UIViewAnimating {

    /// Stops the animation if the animation is not in the `.stopped` state.
    ///
    /// This avoids a runtime crash when stopping a `.stopped` animation.
    ///
    /// See [UIViewAnimating.stopAnimation(Bool)](https://developer.apple.com/documentation/uikit/uiviewanimating/1649750-stopanimation).
    func stopAnimationIfNeeded(withoutFinishing: Bool) {
        guard state != .stopped else {
            return
        }

        stopAnimation(withoutFinishing)
    }
}
