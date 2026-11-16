import Testing
import UIKit
@testable import Modals


@Suite(.serialized)
@MainActor
struct ContentInsetsTests {
    private let bounds = CGRect(x: 0, y: 0, width: 120, height: 100)

    @Test
    func `Zero insets keep the original content hierarchy`() {
        let content = UIView()
        let clipping = ClippingView(content: content)
        clipping.frame = bounds

        clipping.layoutIfNeeded()

        #expect(content.frame == bounds)
        #expect(clipping.subviews == [content])
        #expect(clipping.clipsToBounds)
    }

    @Test
    func `The fill covers overflowing content only outside the hole`() throws {
        let content = UIView()
        let overflow = UIView(frame: CGRect(x: -30, y: -30, width: 180, height: 160))
        overflow.backgroundColor = .green
        content.addSubview(overflow)
        let clipping = ClippingView(content: content)
        clipping.frame = bounds
        clipping.contentInsets = UIEdgeInsets(top: 10, left: 15, bottom: 20, right: 25)
        clipping.contentInsetsFillColor = .blue
        clipping.layoutIfNeeded()

        let fill = try #require(clipping.subviews.last as? InsetFillView)
        #expect(!fill.isUserInteractionEnabled)
        #expect(!fill.isAccessibilityElement)
        #expect(fill.accessibilityElementsHidden)
        #expect(fill.hitTest(CGPoint(x: 1, y: 1), with: nil) == nil)
        try expectImage(of: clipping, background: .blue, contentColor: .green, contentFrame: content.frame)
    }

    @Test
    func `Fill strips keep their edge when the inset moves to the other side`() throws {
        let fill = InsetFillView(frame: bounds)
        fill.fillColor = .blue
        fill.holeFrame = CGRect(x: 20, y: 0, width: 100, height: 100)
        fill.layoutIfNeeded()
        let originalStrips = fill.subviews
        let leftStrip = try #require(originalStrips.first { $0.frame == CGRect(x: 0, y: 0, width: 20, height: 100) })

        fill.holeFrame = CGRect(x: 0, y: 0, width: 100, height: 100)
        fill.layoutIfNeeded()

        let rightStrip = try #require(fill.subviews.first { $0.frame == CGRect(x: 100, y: 0, width: 20, height: 100) })
        #expect(leftStrip !== rightStrip)
        #expect(leftStrip.frame.isEmpty)
        #expect(fill.subviews.elementsEqual(originalStrips) { $0 === $1 })
    }

    private func expectImage(
        of view: UIView,
        background: UIColor,
        contentColor: UIColor,
        contentFrame: CGRect
    ) throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        format.preferredRange = .standard
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        let actual = renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
        let expected = renderer.image { _ in
            background.setFill()
            UIRectFill(bounds)
            contentColor.setFill()
            UIRectFill(contentFrame)
        }

        #expect(try #require(actual.pngData()) == #require(expected.pngData()))
    }
}
