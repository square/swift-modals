import UIKit

/// Models the different types of animation options for modal transitions.
public enum ModalAnimation: Equatable {
    /// An animation based off a `UIView.AnimationCurve`.
    case curve(UIView.AnimationCurve, duration: TimeInterval)

    /// An animation whose easing curve is determined by two control points.
    case cubicBezier(controlPoint1: CGPoint, controlPoint2: CGPoint, duration: TimeInterval)

    /// A spring animation based on a damping ratio and initial velocity.
    case dampenedSpring(dampingRatio: CGFloat = 1, initialVelocity: CGVector = .zero, duration: TimeInterval)

    /// A spring animation based off the physics of an object with mass, a spring stiffness and damping,
    /// and initial velocity. The duration of the animation is determined by the physics of the spring.
    ///
    /// The default arguments for each parameter match those of the system spring animation used for transitions
    /// such as modal presentation, navigation controller push/pop, and keyboard animations. You can match that
    /// animation with `.spring()`.
    case spring(
        mass: CGFloat = 3,
        stiffness: CGFloat = 1000,
        damping: CGFloat = 500,
        initialVelocity: CGVector = .zero
    )
}

extension UIViewPropertyAnimator {
    convenience init(animation: ModalAnimation, animations: (() -> Void)? = nil) {
        switch animation {
        case .curve(let curve, let duration):
            self.init(duration: duration, curve: curve, animations: animations)

        case .cubicBezier(let controlPoint1, let controlPoint2, let duration):
            self.init(
                duration: duration,
                controlPoint1: controlPoint1,
                controlPoint2: controlPoint2
            )

        case .dampenedSpring(let dampingRatio, let initialVelocity, let duration):
            let parameters = UISpringTimingParameters(
                dampingRatio: dampingRatio,
                initialVelocity: initialVelocity
            )
            self.init(duration: duration, timingParameters: parameters)

        case .spring(let mass, let stiffness, let damping, let initialVelocity):
            let parameters = UISpringTimingParameters(
                mass: mass,
                stiffness: stiffness,
                damping: damping,
                initialVelocity: initialVelocity
            )
            self.init(duration: 0, timingParameters: parameters)
        }

        if let animations {
            addAnimations(animations)
        }
    }
}
