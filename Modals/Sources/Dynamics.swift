import UIKit

enum Dynamics {
    static let defaultDeceleration = UIScrollView.DecelerationRate.normal

    /// Project the distance traveled in pts based on an initial velocity in pts/s
    /// (the units for a pan gesture) and deceleration rate.
    ///
    /// Based on sample code from "Designing Fluid Interfaces" WWDC 2018. The original formula is
    /// `(initialVelocity / 1000) * decelerationRate / (1 - decelerationRate)`, but it has been
    /// optimized below for floating point accuracy.
    ///
    /// - Tag: projectDistance
    ///
    /// - Parameters:
    ///   - initialVelocity: The current velocity in pts/s.
    ///   - decelerationRate: The rate of deceleration. Defaults to
    ///     `UIScrollView.DecelerationRate.normal`. Must be between 0-1, non-inclusive;
    ///     providing a value less than or equal to zero, or greater than or equal to 1, is a
    ///     programmer error.
    /// - Returns: The projected distance travelled based on the velocity and deceleration rate.
    static func projectedDistance(
        initialVelocity: CGFloat,
        decelerationRate: UIScrollView.DecelerationRate = defaultDeceleration
    ) -> CGFloat {
        precondition(
            decelerationRate.rawValue < 1 && decelerationRate.rawValue > 0,
            "Deceleration rate must be greater than 0 and less than 1 to compute a finite distance traveled"
        )
        return initialVelocity / ((1000 / decelerationRate.rawValue) - 1000)
    }

    /// Project a destination frame for the given frame, velocity, and deceleration rate.
    ///
    /// - See Also: [projectDistance](x-source-tag://projectDistance)
    ///
    /// - Parameters:
    ///   - frame: The current frame to project a new frame from.
    ///   - initialVelocity: The current velocity in pts/s.
    ///   - decelerationRate: The rate of deceleration. Defaults to
    ///     `UIScrollView.DecelerationRate.normal`. Must be between 0-1, non-inclusive;
    ///     providing a value less than or equal to zero, or greater than or equal to 1, is a
    ///     programmer error.
    /// - Returns: The projected frame based on the velocity and deceleration rate.
    static func projectedFrame(
        from frame: CGRect,
        initialVelocity: CGPoint,
        decelerationRate: UIScrollView.DecelerationRate = defaultDeceleration
    ) -> CGRect {
        frame.offsetBy(
            dx: projectedDistance(
                initialVelocity: initialVelocity.x,
                decelerationRate: decelerationRate
            ),
            dy: projectedDistance(
                initialVelocity: initialVelocity.y,
                decelerationRate: decelerationRate
            )
        )
    }
}
