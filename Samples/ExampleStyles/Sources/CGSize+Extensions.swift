import UIKit

extension CGSize {
    /// Initialize a size with an offset. The height and width of the size reflect the offsets vertical and horizontal
    /// values.
    init(_ offset: UIOffset) {
        self.init(width: offset.horizontal, height: offset.vertical)
    }

    /// Initialize a square size.
    public init(uniform length: CGFloat) {
        self.init(width: length, height: length)
    }

    /// Decrease the size by a given inset.
    public func subtracting(insets: UIEdgeInsets) -> CGSize {
        CGSize(
            width: width - insets.left - insets.right,
            height: height - insets.top - insets.bottom
        )
    }

    /// Decrease the height of the size by a given value.
    public func subtracting(height amount: CGFloat) -> CGSize {
        CGSize(width: width, height: height - amount)
    }

    /// Decrease the width of the size by a given value.
    public func subtracting(width amount: CGFloat) -> CGSize {
        CGSize(width: width - amount, height: height)
    }

    /// Clamp the size to a maximum.
    public func upperBounded(by size: CGSize) -> CGSize {
        CGSize(
            width: width.upperBounded(by: size.width),
            height: height.upperBounded(by: size.height)
        )
    }

    /// Clamp the size's width to a maximum.
    public func upperBounded(byWidth maxWidth: CGFloat?) -> CGSize {
        guard let maxWidth else {
            return self
        }

        return CGSize(width: width.upperBounded(by: maxWidth), height: height)
    }

    /// Clamp the size's height to a maximum.
    public func upperBounded(byHeight maxHeight: CGFloat?) -> CGSize {
        guard let maxHeight else {
            return self
        }

        return CGSize(width: width, height: height.upperBounded(by: maxHeight))
    }

    /// Clamp the size to a minimum.
    public func lowerBounded(by size: CGSize) -> CGSize {
        CGSize(
            width: width.lowerBounded(by: size.width),
            height: height.lowerBounded(by: size.height)
        )
    }

    /// Clamp the size's width to a minimum.
    public func lowerBounded(byWidth minWidth: CGFloat?) -> CGSize {

        guard let minWidth else {
            return self
        }

        return CGSize(width: width.lowerBounded(by: minWidth), height: height)
    }

    /// Clamp the size's height to a minimum.
    public func lowerBounded(byHeight minHeight: CGFloat?) -> CGSize {

        guard let minHeight else {
            return self
        }

        return CGSize(width: width, height: height.lowerBounded(by: minHeight))
    }
}
