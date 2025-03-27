import UIKit

extension UICoordinateSpace {
    /// Converts insets from the coordinate space of the current object to the specified coordinate space.
    ///
    /// Note that each edge of the result is clamped to `0...insets.edge`, e.g., any edge of `coordinateSpace` that does
    /// not overlap with `insets` will be zero, and any edge that extends past the bounds of the receiver will be the
    /// the value of the edge from `insets`.
    ///
    /// - Parameters:
    ///   - insets: An inset specified in the coordinate system of the current object.
    ///   - coordinateSpace: The coordinate space into which insets is to be converted.
    /// - Returns: Insets specified in the target coordinate space.
    func convert(_ insets: UIEdgeInsets, to coordinateSpace: UICoordinateSpace) -> UIEdgeInsets {
        let toBounds = coordinateSpace.convert(coordinateSpace.bounds, to: self)

        func clamp(value: CGFloat, for path: KeyPath<UIEdgeInsets, CGFloat>) -> CGFloat {
            let inset = insets[keyPath: path]
            return min(inset, max(0, value))
        }

        let top = insets.top - (toBounds.minY - bounds.minY)
        let left = insets.left - (toBounds.minX - bounds.minX)
        let bottom = insets.bottom - (bounds.maxY - toBounds.maxY)
        let right = insets.right - (bounds.maxX - toBounds.maxX)

        return UIEdgeInsets(
            top: clamp(value: top, for: \.top),
            left: clamp(value: left, for: \.left),
            bottom: clamp(value: bottom, for: \.bottom),
            right: clamp(value: right, for: \.right)
        )
    }
}
