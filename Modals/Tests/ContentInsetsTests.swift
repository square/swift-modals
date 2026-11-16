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
    func `Content can be inset on all four edges without a fill`() {
        let content = UIView()
        let clipping = ClippingView(content: content)
        clipping.frame = bounds
        clipping.apply(contentInsetsOf: ModalDisplayValues(
            frame: bounds,
            contentInsets: UIEdgeInsets(top: 10, left: 15, bottom: 20, right: 25)
        ))

        clipping.layoutIfNeeded()

        #expect(content.frame == CGRect(x: 15, y: 10, width: 80, height: 70))
        #expect(clipping.subviews == [content])
    }

    @Test
    func `Clearing the fill leaves the inset area transparent`() throws {
        let content = UIView()
        content.backgroundColor = .red
        let clipping = ClippingView(content: content)
        clipping.frame = bounds
        clipping.contentInsets = UIEdgeInsets(top: 10, left: 15, bottom: 20, right: 25)
        clipping.contentInsetsFillColor = .blue
        clipping.layoutIfNeeded()

        clipping.contentInsetsFillColor = nil
        clipping.layoutIfNeeded()

        #expect(content.frame == CGRect(x: 15, y: 10, width: 80, height: 70))
        try expectImage(of: clipping, background: nil, contentColor: .red, contentFrame: content.frame)
    }

    @Test
    func `Resetting the insets restores full size content`() throws {
        let content = UIView()
        content.backgroundColor = .red
        let clipping = ClippingView(content: content)
        clipping.frame = bounds
        clipping.contentInsets = UIEdgeInsets(top: 10, left: 15, bottom: 20, right: 25)
        clipping.contentInsetsFillColor = .blue
        clipping.layoutIfNeeded()

        clipping.contentInsets = .zero
        clipping.layoutIfNeeded()

        #expect(content.frame == bounds)
        try expectImage(of: clipping, background: nil, contentColor: .red, contentFrame: bounds)
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

    @Test
    func `A hole outside the fill bounds leaves the entire fill visible`() throws {
        let fill = InsetFillView(frame: bounds)
        fill.fillColor = .blue
        fill.holeFrame = CGRect(x: 150, y: 120, width: 20, height: 20)
        fill.layoutIfNeeded()

        try expectImage(of: fill, background: .blue, contentColor: .clear, contentFrame: .zero)
    }

    @Test
    func `Presentation layout updates content insets when the modal frame stays the same`() throws {
        let modal = UIViewController()
        let style = InsetStyle()
        let subject = ModalPresentationViewController(content: UIViewController())
        subject.view.frame = bounds
        subject.update(modals: [PresentableModal(
            viewController: modal,
            presentationStyle: style,
            info: .empty(),
            onDidPresent: nil
        )])
        subject.view.layoutIfNeeded()
        let clipping = try #require(modal.view.superview as? ClippingView)
        let presentationFrame = clipping.superview?.frame
        #expect(modal.view.frame == bounds)

        style.insets = UIEdgeInsets(top: 10, left: 15, bottom: 20, right: 25)
        subject.setNeedsPresentationLayout()
        subject.view.layoutIfNeeded()

        #expect(clipping.superview?.frame == presentationFrame)
        #expect(modal.view.frame == CGRect(x: 15, y: 10, width: 80, height: 70))
    }

    private func expectImage(
        of view: UIView,
        background: UIColor?,
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
            if let background {
                background.setFill()
                UIRectFill(bounds)
            }
            contentColor.setFill()
            UIRectFill(contentFrame)
        }

        #expect(try #require(actual.pngData()) == #require(expected.pngData()))
    }

    private final class InsetStyle: ModalPresentationStyle {
        var insets: UIEdgeInsets = .zero

        func behaviorPreferences(for context: ModalBehaviorContext) -> ModalBehaviorPreferences {
            ModalBehaviorPreferences(usesPreferredContentSize: false)
        }

        func displayValues(for context: ModalPresentationContext) -> ModalDisplayValues {
            MainActor.assumeIsolated {
                ModalDisplayValues(frame: context.containerCoordinateSpace.bounds, contentInsets: insets)
            }
        }

        func enterTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
            MainActor.assumeIsolated {
                ModalTransitionValues(frame: context.containerCoordinateSpace.bounds)
            }
        }

        func exitTransitionValues(for context: ModalPresentationContext) -> ModalTransitionValues {
            MainActor.assumeIsolated {
                ModalTransitionValues(frame: context.containerCoordinateSpace.bounds)
            }
        }
    }
}
