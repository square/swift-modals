import Foundation
import UIKit


extension ModalTransitionValues {

    /// Derives a set of transition values for a simple cross fade, by taking the final display values and setting the
    /// opacity values to `0`. You can use this convenience to replace a moving transition when
    /// `UIAccessibility.prefersCrossFadeTransitions` is `true` and ``ModalPresentationContext/isInteractive`` is
    /// `false`.
    public static func crossFadeValues(
        from displayValues: ModalDisplayValues,
        animation: ModalAnimation = .curve(.easeInOut, duration: 0.3)
    ) -> Self {
        ModalTransitionValues(
            frame: displayValues.frame,
            alpha: 0,
            transform: .identity,
            overlayOpacity: 0,
            roundedCorners: displayValues.roundedCorners,
            decorationOpacity: 0,
            animation: animation
        )
    }
}
