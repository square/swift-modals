import Foundation
import UIKit

extension CGSize {
    init(_ offset: UIOffset) {
        self.init(width: offset.horizontal, height: offset.vertical)
    }
}
