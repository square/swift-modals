import Modals
import UIKit

extension ModalDecoration {
    /// Describes a handle which is typically attached to the top of a sheet to hint
    /// at interactive dismissal.
    ///
    /// - Parameters:
    ///   - frame: The frame of the handle.
    ///   - color: The color of the handle.
    ///   - size: The size of the handle.
    ///   - offset: The distance from the top of the modal to the bottom of the handle.
    /// - Returns: A `ModalDecoration` representing a handle.
    static func handle(
        in frame: CGRect,
        color: UIColor,
        size: CGSize,
        offset: CGFloat
    ) -> ModalDecoration {
        let frame = CGRect(
            origin: CGPoint(
                x: (frame.width - size.width) / 2,
                y: -offset - size.height
            ),
            size: size
        )
        let corners = ModalRoundedCorners(radius: size.height / 2)

        return ModalDecoration(
            frame: frame,
            build: UIView.init,
            update: { handle in
                handle.backgroundColor = color
                corners.apply(toView: handle)
            }
        )
    }
}
