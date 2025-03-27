import UIKit


/// A collection of values that describes the available size for a toast to layout in during the "preheat" pass.
///
/// The toast's view controller contents are laid out in sizes returned from this function before the
/// `preferredContentSize` is queried on the view controller.
///
public struct ToastPreheatValues {

    /// The maximum size of a toast which is used during a preheat pass.
    ///
    /// The toast's view controller contents are laid out in this size before the `preferredContentSize` is queried on
    /// the view controller.
    ///
    public var size: CGSize

    /// Creates a new set of preheat values.
    ///
    public init(size: CGSize) {
        self.size = size
    }
}
