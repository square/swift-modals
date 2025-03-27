import UIKit


extension UIView {
    /// Avoids possible issues setting the frame and transform by first setting the transform to the
    /// identity, then setting the frame, then setting the provided transform.
    ///
    /// Setting the center, bounds, or frame may cause a synchronous layout. By setting the frame
    /// instead of center and bounds we can minimize the number of layouts.
    ///
    func set(frame: CGRect, transform: CGAffineTransform) {
        if self.transform != .identity {
            self.transform = .identity
        }

        if self.frame != frame {
            self.frame = frame
        }

        if self.transform != transform {
            self.transform = transform
        }
    }

    var presentationOrRealLayer: CALayer {
        layer.presentation() ?? layer
    }
}
