import UIKit


public struct ToastPreheatContext {

    public var containerSize: CGSize

    public var safeAreaInsets: UIEdgeInsets

    public init(
        containerSize: CGSize,
        safeAreaInsets: UIEdgeInsets
    ) {
        self.containerSize = containerSize
        self.safeAreaInsets = safeAreaInsets
    }
}
