import UIKit

extension CACornerMask {
    /// A mask containing all the corners.
    public static let all: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner,
        .layerMaxXMaxYCorner,
        .layerMinXMaxYCorner,
    ]

    /// A mask containing only the top corners: `[.layerMinXMinYCorner, .layerMaxXMinYCorner]`
    public static let top: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner,
    ]

    /// A mask containing only the left corners: `[.layerMinXMinYCorner, .layerMinXMaxYCorner]`
    public static let left: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMinXMaxYCorner,
    ]

    /// A mask containing only the right corners: `[.layerMaxXMinYCorner, .layerMaxXMaxYCorner]`
    public static let right: CACornerMask = [
        .layerMaxXMinYCorner,
        .layerMaxXMaxYCorner,
    ]
}

extension UIRectCorner {
    init(cornerMask: CACornerMask) {
        self.init()

        if cornerMask.contains(.layerMinXMinYCorner) {
            insert(.topLeft)
        }
        if cornerMask.contains(.layerMaxXMinYCorner) {
            insert(.topRight)
        }
        if cornerMask.contains(.layerMinXMaxYCorner) {
            insert(.bottomLeft)
        }
        if cornerMask.contains(.layerMaxXMaxYCorner) {
            insert(.bottomRight)
        }
    }
}
