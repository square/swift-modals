import XCTest
@testable import Modals

class ConvertInsetsTests: XCTestCase {
    func test_coordinateSpaceInsetsNoOverlap() {
        let view1 = UIView(frame: .init(origin: .zero, size: .init(width: 100, height: 100)))
        let view2 = UIView(frame: view1.bounds.insetBy(dx: 20, dy: 20))

        view1.addSubview(view2)
        let insets = view1.convert(UIEdgeInsets(uniform: 10), to: view2)
        XCTAssertEqual(insets, .zero)
    }

    func test_coordinateSpaceInsetsPartialOverlap() {
        let view1 = UIView(frame: .init(origin: .zero, size: .init(width: 100, height: 100)))
        let view2 = UIView(frame: view1.bounds.insetBy(dx: 5, dy: 5))

        view1.addSubview(view2)
        let insets = view1.convert(UIEdgeInsets(uniform: 10), to: view2)
        XCTAssertEqual(insets, .init(uniform: 5))
    }

    func test_coordinateSpaceInsetsFullOverlap() {
        let view1 = UIView(frame: .init(origin: .zero, size: .init(width: 100, height: 100)))
        let view2 = UIView(frame: view1.bounds)

        view1.addSubview(view2)
        let insets = view1.convert(UIEdgeInsets(uniform: 10), to: view2)
        XCTAssertEqual(insets, .init(uniform: 10))
    }

    func test_coordinateSpaceInsetsOutsetOverlap() {
        let view1 = UIView(frame: .init(origin: .zero, size: .init(width: 100, height: 100)))
        let view2 = UIView(frame: view1.bounds.insetBy(dx: -20, dy: -20))

        view1.addSubview(view2)
        let insets = view1.convert(UIEdgeInsets(uniform: 10), to: view2)
        XCTAssertEqual(insets, .init(uniform: 10))
    }

}

extension UIEdgeInsets {
    init(uniform inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }
}
